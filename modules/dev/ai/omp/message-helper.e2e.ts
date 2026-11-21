import { afterEach, beforeEach, describe, expect, it } from "bun:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { type } from "@oh-my-pi/omptype";
import { Agent, type AgentTool } from "@oh-my-pi/pi-agent-core";
import type { AssistantMessage, Context } from "@oh-my-pi/pi-ai";
import { createMockModel } from "@oh-my-pi/pi-ai/providers/mock";
import { AssistantMessageEventStream } from "@oh-my-pi/pi-ai/utils/event-stream";
import { ModelRegistry } from "@oh-my-pi/pi-coding-agent/config/model-registry";
import { Settings } from "@oh-my-pi/pi-coding-agent/config/settings";
import { IrcBus } from "@oh-my-pi/pi-coding-agent/irc/bus";
import { executeSend } from "@oh-my-pi/pi-coding-agent/irc/messaging";
import { initializeExtensions } from "@oh-my-pi/pi-coding-agent/modes/runtime-init";
import { AgentRegistry } from "@oh-my-pi/pi-coding-agent/registry/agent-registry";
import { type CreateAgentSessionOptions, createAgentSession } from "@oh-my-pi/pi-coding-agent/sdk";
import { AgentSession } from "@oh-my-pi/pi-coding-agent/session/agent-session";
import type { AuthStorage } from "@oh-my-pi/pi-coding-agent/session/auth-storage";
import { convertToLlm } from "@oh-my-pi/pi-coding-agent/session/messages";
import { SessionManager } from "@oh-my-pi/pi-coding-agent/session/session-manager";
import { Snowflake } from "@oh-my-pi/pi-utils";
import { createInMemoryAuthStorage } from "./helpers/agent-session-setup";
import messageHelperExtension, { messageHelper } from "./finix-message-helper";

const zeroUsage = {
	input: 0,
	output: 0,
	cacheRead: 0,
	cacheWrite: 0,
	totalTokens: 0,
	cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
} satisfies AssistantMessage["usage"];

type Tool = { execute: (id: string, params: unknown) => Promise<{ content: Array<{ type: string; text?: string }> }> };

describe("message_helper", () => {
	let tempDir: string;
	const authStorages: AuthStorage[] = [];
	const sessions: AgentSession[] = [];

	beforeEach(() => {
		AgentRegistry.resetGlobalForTests();
		IrcBus.resetGlobalForTests();
		tempDir = path.join(os.tmpdir(), `finix-message-helper-${Snowflake.next()}`);
		fs.mkdirSync(tempDir, { recursive: true });
	});

	afterEach(async () => {
		for (const session of sessions.splice(0)) await session.dispose();
		for (const authStorage of authStorages.splice(0)) authStorage.close();
		fs.rmSync(tempDir, { recursive: true, force: true });
	});

	async function sdkSession(options: Partial<CreateAgentSessionOptions> = {}): Promise<AgentSession> {
		const authStorage = createInMemoryAuthStorage();
		authStorages.push(authStorage);
		const { session } = await createAgentSession({
			cwd: tempDir,
			agentDir: tempDir,
			authStorage,
			modelRegistry: new ModelRegistry(authStorage, path.join(tempDir, "models.yml")),
			settings: Settings.isolated(),
			sessionManager: SessionManager.inMemory(),
			disableExtensionDiscovery: true,
			extensions: [messageHelperExtension],
			skills: [],
			contextFiles: [],
			promptTemplates: [],
			slashCommands: [],
			enableMCP: false,
			enableLsp: false,
			skipPythonPreflight: true,
			rules: [],
			preloadedCustomToolPaths: [],
			toolNames: ["read"],
			...options,
		});
		sessions.push(session);
		await initializeExtensions(session, { reportSendError: () => {}, reportRuntimeError: () => {} });
		return session;
	}

	async function parentTool(): Promise<Tool> {
		const parent = await sdkSession();
		expect(AgentRegistry.global().get("Main")?.session).toBeTruthy();
		const tool = parent.getToolByName("message_helper") as unknown as Tool | undefined;
		expect(tool).toBeDefined();
		return tool!;
	}

	function mockHelper(id: string, script: (call: number) => AssistantMessage["content"], tools: AgentTool[] = []) {
		const model = createMockModel({ provider: "openai", id: "gpt-test" }).model;
		const authStorage = createInMemoryAuthStorage();
		authStorages.push(authStorage);
		authStorage.keys.setRuntime("openai", "openai-test-key");
		const contexts: Context[] = [];
		const nextCall: Array<() => void> = [];
		const agent = new Agent({
			getApiKey: () => "test-key",
			initialState: { model, systemPrompt: ["Helper"], tools, messages: [] },
			convertToLlm,
			streamFn: (_model, context) => {
				contexts.push(context);
				const content = script(contexts.length - 1);
				const toolUse = content.some(block => block.type === "toolCall");
				const message: AssistantMessage = {
					role: "assistant",
					content,
					api: model.api,
					provider: model.provider,
					model: model.id,
					usage: zeroUsage,
					stopReason: toolUse ? "toolUse" : "stop",
					timestamp: Date.now(),
				};
				const stream = new AssistantMessageEventStream();
				queueMicrotask(() => {
					stream.push({ type: "start", partial: message });
					stream.push({ type: "done", reason: toolUse ? "toolUse" : "stop", message });
					for (const resolve of nextCall.splice(0)) resolve();
				});
				return stream;
			},
		});
		const settings = Settings.isolated({ "compaction.enabled": false, "todo.enabled": false });
		settings.setModelRole("default", `${model.provider}/${model.id}`);
		const session = new AgentSession({
			agent,
			sessionManager: SessionManager.inMemory(tempDir),
			settings,
			modelRegistry: new ModelRegistry(authStorage),
			toolRegistry: new Map(tools.map(tool => [tool.name, tool])),
		});
		sessions.push(session);
		AgentRegistry.global().register({
			id,
			displayName: id,
			kind: "sub",
			parentId: "Main",
			session,
			status: "running",
			history: { agent: "task" },
		});
		const called = () => {
			const { promise, resolve } = Promise.withResolvers<void>();
			nextCall.push(resolve);
			return promise;
		};
		return { session, contexts, called };
	}

	const text = (result: { content: Array<{ type: string; text?: string }> }) =>
		result.content.map(part => part.text ?? "").join("\n");

	it("a running helper receives the message at its next step boundary, never mid-tool", async () => {
		const tool = await parentTool();
		const started = Promise.withResolvers<void>();
		const release = Promise.withResolvers<void>();
		let toolAborted = false;
		const slow: AgentTool = {
			name: "slow",
			label: "Slow",
			description: "Blocks until released",
			parameters: type({}),
			execute: async (_id, _params, signal) => {
				signal?.addEventListener("abort", () => {
					toolAborted = true;
				});
				started.resolve();
				await release.promise;
				return { content: [{ type: "text", text: "SLOW_DONE" }] };
			},
		};
		const helper = mockHelper(
			"Helper",
			call => (call === 0 ? [{ type: "toolCall", id: "tc-0", name: "slow", arguments: {} }] : [{ type: "text", text: "ok" }]),
			[slow],
		);
		const run = helper.session.prompt("work");
		await started.promise;

		const result = await tool.execute("mh-1", { to: "Helper", message: "PARENT_NOTE_MIDSTEP" });
		expect(text(result)).toContain("next step boundary");
		expect(toolAborted).toBe(false);
		expect(helper.session.agent.peekSteeringQueue()).toHaveLength(0);
		expect(JSON.stringify(helper.contexts)).not.toContain("PARENT_NOTE_MIDSTEP");

		release.resolve();
		await run;
		await helper.session.waitForIdle();

		expect(toolAborted).toBe(false);
		expect(helper.contexts).toHaveLength(2);
		const second = JSON.stringify(helper.contexts[1]!.messages);
		expect(second).toContain("SLOW_DONE");
		expect(second).toContain("PARENT_NOTE_MIDSTEP");
		expect(second.indexOf("SLOW_DONE")).toBeLessThan(second.indexOf("PARENT_NOTE_MIDSTEP"));
	});

	it("a helper between turns is woken to read the message", async () => {
		const tool = await parentTool();
		const helper = mockHelper("Idle", () => [{ type: "text", text: "ack" }]);
		await helper.session.prompt("first");
		await helper.session.waitForIdle();
		AgentRegistry.global().setStatus("Idle", "idle");
		expect(helper.contexts).toHaveLength(1);

		const woke = helper.called();
		const result = await tool.execute("mh-2", { to: "Idle", message: "PARENT_NOTE_WAKE" });
		expect(text(result)).toContain("woken");
		await woke;
		await helper.session.waitForIdle();
		expect(helper.contexts).toHaveLength(2);
		expect(JSON.stringify(helper.contexts[1]!.messages)).toContain("PARENT_NOTE_WAKE");
	});

	it("resolves a helper by task job id", async () => {
		await parentTool();
		const helper = mockHelper("ByJob", () => [{ type: "text", text: "ack" }]);
		await helper.session.prompt("first");
		await helper.session.waitForIdle();
		const woke = helper.called();
		const result = await messageHelper({
			senderId: "Main",
			to: "job_7",
			message: "PARENT_NOTE_JOB",
			jobs: { running: [{ id: "job_7", type: "task", status: "running", agentId: "ByJob" }], recent: [] },
		});
		expect(result.to).toBe("ByJob");
		await woke;
		await helper.session.waitForIdle();
		expect(JSON.stringify(helper.contexts[1]!.messages)).toContain("PARENT_NOTE_JOB");
	});

	it("trusts a live helper over a stale completed job", async () => {
		await parentTool();
		const helper = mockHelper("Rewoken", () => [{ type: "text", text: "ack" }]);
		await helper.session.prompt("first");
		await helper.session.waitForIdle();
		const woke = helper.called();
		const result = await messageHelper({
			senderId: "Main",
			to: "Rewoken",
			message: "PARENT_NOTE_REWOKEN",
			jobs: { running: [], recent: [{ id: "Rewoken", type: "task", status: "completed", agentId: "Rewoken" }] },
		});
		expect(result.outcome).toBe("woken");
		await woke;
		await helper.session.waitForIdle();
		expect(JSON.stringify(helper.contexts[1]!.messages)).toContain("PARENT_NOTE_REWOKEN");
	});

	it("refuses Goldfish audit agents on every path", async () => {
		const tool = await parentTool();
		const audit = await sdkSession({
			taskDepth: 1,
			parentTaskPrefix: "goldfish-1a2b3c4d",
			agentId: "goldfish-1a2b3c4d",
			agentDisplayName: "goldfish",
			agentName: "goldfish",
			parentAgentId: "Main",
		});
		const named = await sdkSession({
			taskDepth: 1,
			parentTaskPrefix: "AuditPass",
			agentId: "AuditPass",
			agentDisplayName: "AuditPass",
			agentName: "goldfish",
			parentAgentId: "Main",
		});
		expect(audit.getToolByName("message_helper")).toBeUndefined();
		expect(named.getToolByName("message_helper")).toBeUndefined();
		for (const id of ["goldfish-1a2b3c4d", "AuditPass"]) {
			expect(AgentRegistry.global().get(id)?.history?.agent).toBe("goldfish");
			await expect(tool.execute("mh-g", { to: id, message: "PEEK" })).rejects.toThrow(/Goldfish audit agent/);
			await expect(
				messageHelper({
					senderId: "Main",
					to: "job_9",
					message: "PEEK",
					jobs: { running: [{ id: "job_9", type: "task", status: "running", agentId: id }], recent: [] },
				}),
			).rejects.toThrow(/Goldfish audit agent/);
			const receipt = await IrcBus.global().send({ from: "Main", to: id, body: "PEEK" });
			expect(receipt.outcome).toBe("failed");
			expect(receipt.error).toMatch(/Goldfish audit agent/);
		}
		const broadcast = await executeSend({ registry: AgentRegistry.global(), senderId: "Main" }, { to: "all", message: "PEEK" });
		expect(JSON.stringify(broadcast.details)).not.toContain("goldfish-1a2b3c4d");
		expect(JSON.stringify(broadcast.details)).not.toContain("AuditPass");
		const leaked = [audit, named].flatMap(session => session.agent.state.messages).filter(m => JSON.stringify(m).includes("PEEK"));
		expect(leaked).toHaveLength(0);
	});

	it("errors clearly for unknown, finished and non-descendant helpers", async () => {
		const tool = await parentTool();
		const registry = AgentRegistry.global();
		await expect(tool.execute("mh-u", { to: "Nobody", message: "hi" })).rejects.toThrow(/Unknown helper "Nobody"/);

		const done = mockHelper("Done", () => [{ type: "text", text: "ack" }]);
		registry.markResultAccepted("Done", done.session);
		await expect(tool.execute("mh-f", { to: "Done", message: "hi" })).rejects.toThrow(/already finished/);

		const parked = mockHelper("Parked", () => [{ type: "text", text: "ack" }]);
		registry.setStatus("Parked", "parked", parked.session);
		await expect(tool.execute("mh-p", { to: "Parked", message: "hi" })).rejects.toThrow(/already finished/);

		registry.register({ id: "Starting", displayName: "Starting", kind: "sub", parentId: "Main", session: null, status: "running" });
		await expect(tool.execute("mh-st", { to: "Starting", message: "hi" })).rejects.toThrow(/still starting/);

		await expect(
			messageHelper({
				senderId: "Main",
				to: "Gone",
				message: "hi",
				jobs: { running: [], recent: [{ id: "Gone", type: "task", status: "completed", agentId: "Gone" }] },
			}),
		).rejects.toThrow(/already finished/);

		registry.register({ id: "Other", displayName: "Other", kind: "sub", session: null, status: "running" });
		const stranger = mockHelper("Stranger", () => [{ type: "text", text: "ack" }]);
		registry.register({
			id: "Stranger",
			displayName: "Stranger",
			kind: "sub",
			parentId: "Other",
			session: stranger.session,
			status: "running",
		});
		await expect(tool.execute("mh-n", { to: "Stranger", message: "hi" })).rejects.toThrow(/not one of your helpers/);
		await expect(tool.execute("mh-s", { to: "Main", message: "hi" })).rejects.toThrow(/cannot message yourself/);
		expect(JSON.stringify(stranger.session.agent.state.messages)).not.toContain('"hi"');
	});
});
