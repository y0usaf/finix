/**
 * Code mode for omp, extension-only.
 *
 * The provider request carries `eval` alone; every other enabled tool stays in
 * the session registry, so `await tool.<name>(args)` inside an eval cell still
 * dispatches through the normal tool pipeline. Declarations for the demoted
 * tools are spliced into the system prompt, replacing the rendered tool
 * inventory.
 */

const DIRECT_TOOLS = new Set(["eval", "think", "yield", "goal", "checkpoint", "rewind"]);
const INVENTORY_HEADING = "\n# Tool Inventory\n";
const MAX_DECLARATION_CHARS = 64 * 1024;
const TS_IDENTIFIER = /^[A-Za-z_$][A-Za-z0-9_$]*$/;

function wireSchema(parameters) {
	if (!parameters) return undefined;
	if (typeof parameters.toJsonSchema === "function") {
		try {
			return parameters.toJsonSchema();
		} catch {
			return undefined;
		}
	}
	try {
		return JSON.parse(JSON.stringify(parameters));
	} catch {
		return undefined;
	}
}

function tsType(schema, depth) {
	if (!schema || depth > 2) return "unknown";
	if (Array.isArray(schema.enum) && schema.enum.every(value => typeof value === "string")) {
		return schema.enum.map(value => JSON.stringify(value)).join(" | ");
	}
	switch (schema.type) {
		case "string":
			return "string";
		case "number":
		case "integer":
			return "number";
		case "boolean":
			return "boolean";
		case "array": {
			const item = tsType(schema.items, depth + 1);
			return /[|&]/.test(item) ? `(${item})[]` : `${item}[]`;
		}
		case "object": {
			if (!schema.properties) return "Record<string, unknown>";
			const required = new Set(schema.required ?? []);
			const entries = Object.entries(schema.properties).map(([key, value]) => {
				const printedKey = TS_IDENTIFIER.test(key) ? key : JSON.stringify(key);
				return `${printedKey}${required.has(key) ? "" : "?"}: ${tsType(value, depth + 1)}`;
			});
			return `{ ${entries.join("; ")} }`;
		}
		default:
			return "unknown";
	}
}

function declarationsFor(tools) {

	const lines = [];
	for (const tool of [...tools].sort((a, b) => a.name.localeCompare(b.name))) {
		if (DIRECT_TOOLS.has(tool.name)) continue;
		const wire = wireSchema(tool.parameters);
		const args = wire?.type === "object" && wire.properties ? tsType(wire, 0) : "unknown";
		const printedName = TS_IDENTIFIER.test(tool.name) ? tool.name : JSON.stringify(tool.name);
		lines.push(`  ${printedName}(args: ${args}): Promise<unknown>;`);
	}
	let text = `declare const tool: {\n${lines.join("\n")}\n};`;
	if (text.length > MAX_DECLARATION_CHARS) {
		text = `${text.slice(0, MAX_DECLARATION_CHARS)}\n  // truncated\n};`;
	}
	return text;
}

function codeModeSection(declarations) {
	return `
# Code Mode
\`eval\` is the only tool callable directly. Every other session tool is reachable inside an eval cell as \`await tool.<name>(args)\`:
plan several operations into one cell, run independent calls with \`Promise.all\`, and read \`result.text\` (plus \`result.details\`) instead of expecting a rendered tool card.
Reserve separate cells for steps that must inspect earlier results.

\`\`\`ts
${declarations}
\`\`\`
`;
}

function rewriteInventory(text, declarationText) {
	const start = text.indexOf(INVENTORY_HEADING);
	const bodyStart = start + INVENTORY_HEADING.length;
	const nextHeading = text.indexOf("\n# ", bodyStart);
	const end = nextHeading < 0 ? text.length : nextHeading + 1;
	return `${text.slice(0, start)}${codeModeSection(declarationText)}${text.slice(end)}`;
}

function toolName(tool) {
	const name = tool?.function?.name ?? tool?.name;
	return typeof name === "string" ? name : undefined;
}

function filterPayload(payload) {
	if (!payload || typeof payload !== "object" || !Array.isArray(payload.tools)) return payload;
	const tools = payload.tools.filter(tool => {
		const name = toolName(tool);
		return name !== undefined && DIRECT_TOOLS.has(name);
	});
	const next = { ...payload, tools };
	const choice = payload.tool_choice;
	const forced = typeof choice === "string" ? choice : (choice?.name ?? choice?.function?.name);
	if (typeof forced === "string" && forced !== "auto" && forced !== "none" && !DIRECT_TOOLS.has(forced)) {
		delete next.tool_choice;
	}
	return next;
}

function sessionId(ctx) {
	return ctx?.sessionManager?.getSessionId?.() ?? "default";
}

export default function codeMode(pi) {
	let declarationText = "";
	const insideEval = new Set();

	pi.setLabel("Code mode");

	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName === "eval") {
			insideEval.add(sessionId(ctx));
			return undefined;
		}
		if (DIRECT_TOOLS.has(event.toolName) || insideEval.has(sessionId(ctx))) return undefined;
		return {
			block: true,
			reason: `Direct ${event.toolName} calls are disabled; call tool.${event.toolName}(args) from eval instead.`,
		};
	});

	pi.on("tool_result", async (event, ctx) => {
		if (event.toolName === "eval") insideEval.delete(sessionId(ctx));
	});

	pi.on("before_agent_start", async event => {
		if (!Array.isArray(event.systemPrompt)) return undefined;
		declarationText = declarationsFor(pi.getAllTools());
		const systemPrompt = [...event.systemPrompt];
		const index = systemPrompt.findIndex(
			part => typeof part === "string" && part.includes(INVENTORY_HEADING),
		);
		if (index >= 0) {
			systemPrompt[index] = rewriteInventory(systemPrompt[index], declarationText);
		} else if (systemPrompt.length > 0) {
			const last = systemPrompt.length - 1;
			systemPrompt[last] = `${systemPrompt[last]}\n${codeModeSection(declarationText)}`;
		}
		return { systemPrompt };
	});

	pi.on("before_provider_request", async event => filterPayload(event.payload));
}
