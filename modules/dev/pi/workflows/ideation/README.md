# Ideation workflow

Multi-model debate for [pi-extensible-workflows](https://github.com/vekexasia/pi-extensible-workflows)
(vendored at `@extensions/vekexasia_pi-extensible-workflows/`).

Every participant is a plain **ideator** — no personas. Diversity comes from
different model weights/corpora, not role prompts. Default ideators are cheap
models served via vercel-ai-gateway (`zai/glm-5.2-fast`,
`deepseek/deepseek-v4-flash`); the judge defaults to
`moonshotai/kimi-k3-fast` for reliable structured verdicts.

Each round runs in two passes:

1. **chain** — ideators speak sequentially; each sees everything said before
   them this round and must engage it (attack, defend, concede, merge).
2. **open floor** — everyone sees the full chain and answers the strongest
   objection to their own position.

A Consensus Judge agent with a structured `outputSchema` verdict checks after
every round; the loop runs **until agreement**, stopping only at:

1. **consensus** (judge: `converged: true`),
2. a **human checkpoint** after round 3 (approve to continue, reject to stop),
3. the **round cap** (`maxRounds`, default 5, hard max 10),
4. the **run budget** if one is set (tokens/cost/duration — resumable via
   `workflow_resume` after a budget bump).

The discussion is script-mediated: agents never talk peer-to-peer; the
workflow passes the growing transcript to each participant. Token cost grows
with rounds — keep `maxRounds` low or set a budget for open-ended topics.
With the default cheap models a converging 1-round run costs ~$0.10.

## Prerequisites

Enable the extension in your system flake and rebuild:

```nix
programs.pi.extensions.extensible-workflows = true;
```

The system flake (`modules/dev/pi/workflows.nix`) places this directory into
`~/.local/share/pi/agent/workflows/ideation/`, which the engine scans for
`command.json` — that registers the slash command. The files here are the
source of truth; the home-dir copy is a store symlink, never edited in place.

## Invoke

Bare, with no topic at all — the debate is about whatever the current session
is circling:

```
/ideate
```

The engine renders the active session branch (user and assistant turns, tool
output left out, compaction summaries kept) into the `sessionContext` argument
before the run starts; `command.json` asks for that by declaring
`"sessionContext": { "key": "sessionContext", "maxChars": 12000 }`. The
workflow then spends **one cheap model call** turning that transcript into a
brief — `{ topic, background, openQuestions }` — and debates the topic it
found. Handing the raw transcript to every ideator instead would multiply its
tokens by models x passes x rounds.

With a topic, which fixes the question but keeps the session as background:

```
/ideate a local-first sync engine for my notes
/ideate '{ "topic": "a local-first sync engine for my notes" }'
```

Or via the `workflow` tool (adds a budget backstop). Nothing injects a session
here — the tool path has no slash-command handler, so pass `sessionContext`
yourself if you want one:

```json
{
  "name": "ideate",
  "scriptPath": "/home/y0usaf/dev/pi-flake/workflows/ideation/ideate.js",
  "args": { "topic": "a local-first sync engine for my notes" }
}
```

Optional args:

- `topic` — required only when there is no `sessionContext` to derive it from.
- `sessionContext` — session transcript to build on. Filled in automatically
  for slash launches; a bare `/ideate` in a session with no conversation yet is
  refused with a usage hint instead of starting a run.
- `context` — background info fed to every participant. Kept alongside the
  session brief, never replaced by it.
- `maxRounds` — 1–10, default 5. Raise for hard topics, lower to save tokens.
- `models` — ideator model ids (default: glm-5.2-fast + deepseek-v4-flash via
  vercel-ai-gateway). Must be available models (credentials configured).
- `judgeModel` — defaults to `vercel-ai-gateway/moonshotai/kimi-k3-fast`. Also
  writes the session brief.

Runs are backgrounded by default; completion arrives as a follow-up message.
Add `"foreground": true` when the caller must wait for the final synthesis in
the same turn.

Useful extras:

- Launch with a budget, e.g. `"budget": { "tokens": { "hard": 1000000 } }`,
  as a backstop against a discussion that never converges.
- `workflow_status({ runId })` inspects a running or finished run;
  `workflow_retry({ runId })` replays a failed run without rerunning
  completed agents.

## Model ids and providers

Model ids must include the provider prefix of an *available* model (one with
credentials), e.g. `vercel-ai-gateway/zai/glm-5.2-fast`. A bare id like
`moonshotai/kimi-k3-fast` resolves against the native provider and fails
availability when only the gateway has credentials for it.
