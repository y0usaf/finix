#!/usr/bin/env node
// Jev (TypeSafe System One) MCP server for boar. No dependencies.
// Exposes one tool: jev_decision — typed noul/choice/score decisions
// against POST https://api.typesafe.ai/v1/systemone

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const ENDPOINT = "https://api.typesafe.ai/v1/systemone";
const MODEL = "jev-latest";
const VERSION = "2025-11-25";

function resolveKey() {
  if (process.env.TYPESAFE_API_KEY) return process.env.TYPESAFE_API_KEY.trim();
  try {
    return readFileSync(join(homedir(), "Tokens/TYPESAFE_API_KEY.txt"), "utf8").trim();
  } catch {
    return null;
  }
}

const API_KEY = resolveKey();

const TOOL = {
  name: "jev_decision",
  description: "Make fast, type-safe structured decisions with TypeSafe Jev (System One). " +
    "Given a state (text or JSON) and a map of questions, returns a typed answer per question with " +
    "calibrated probabilities and confidence. Three question primitives: noul (yes/no probability), " +
    "choice (pick one of up to 255 options, with criteria map), score (rate along an ordered rubric " +
    "list of 2-10 levels). All questions evaluate in parallel in one round trip.",
  inputSchema: {
    type: "object",
    properties: {
      state: { type: "string", description: "The program/document state to judge (plain text or JSON)." },
      questions: {
        type: "object",
        description: "Map of answer-key -> question spec. Each spec: {type: 'noul'|'choice'|'score', instructions: string, criteria?: object|string[]}. " +
          "choice criteria is an object of option -> description; score criteria is an ordered array of level labels; noul criteria optional.",
        additionalProperties: {
          type: "object",
          properties: {
            type: { type: "string", enum: ["noul", "choice", "score"] },
            instructions: { type: "string" },
            criteria: { type: "object" }
          },
          required: ["type", "instructions"]
        }
      }
    },
    required: ["state", "questions"]
  }
};

let buf = "";
process.stdin.on("data", (chunk) => {
  buf += chunk.toString();
  let idx;
  while ((idx = buf.indexOf("\n")) >= 0) {
    const line = buf.slice(0, idx).trim();
    buf = buf.slice(idx + 1);
    if (!line) continue;
    let msg;
    try { msg = JSON.parse(line); } catch { continue; }
    handle(msg);
  }
});

function send(obj) { process.stdout.write(JSON.stringify(obj) + "\n"); }

async function callSystemOne(state, questions) {
  if (!API_KEY) throw new Error("TYPESAFE_API_KEY not set and ~/Tokens/TYPESAFE_API_KEY.txt unreadable");
  const res = await fetch(ENDPOINT, {
    method: "POST",
    headers: { "Content-Type": "application/json", "Authorization": "Bearer " + API_KEY },
    body: JSON.stringify({ model: MODEL, state, questions })
  });
  const text = await res.text();
  if (!res.ok) {
    let detail = text;
    try { const j = JSON.parse(text); detail = JSON.stringify(j.detail || j); } catch {}
    throw new Error("Jev API HTTP " + res.status + ": " + detail.slice(0, 500));
  }
  return JSON.parse(text);
}

async function handle(msg) {
  const { id, method, params } = msg;
  if (method === "initialize") {
    return send({ jsonrpc: "2.0", id, result: {
      protocolVersion: VERSION,
      capabilities: { tools: {} },
      serverInfo: { name: "jev-mcp", version: "0.1.0" }
    }});
  }
  if (method === "ping") return send({ jsonrpc: "2.0", id, result: {} });
  if (method === "notifications/initialized") return;
  if (method === "tools/list") {
    return send({ jsonrpc: "2.0", id, result: { tools: [TOOL] } });
  }
  if (method === "tools/call") {
    const name = params?.name;
    const args = params?.arguments || {};
    try {
      if (name !== "jev_decision") throw new Error("Unknown tool: " + name);
      if (typeof args.state !== "string" || !args.state.trim()) throw new Error("state is required and must be a string");
      if (!args.questions || typeof args.questions !== "object") throw new Error("questions map is required");
      const data = await callSystemOne(args.state, args.questions);
      return send({ jsonrpc: "2.0", id, result: {
        content: [{ type: "text", text: JSON.stringify(data, null, 2) }],
        structuredContent: data,
        isError: false
      }});
    } catch (e) {
      return send({ jsonrpc: "2.0", id, result: {
        content: [{ type: "text", text: "Error: " + e.message }],
        isError: true
      }});
    }
  }
  send({ jsonrpc: "2.0", id, error: { code: -32601, message: "Method not found: " + method } });
}
