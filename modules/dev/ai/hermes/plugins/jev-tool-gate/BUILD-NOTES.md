# jev-tool-gate

A Hermes plugin (manifest_version 2, `provides_hooks: [pre_llm_call, pre_tool_call]`, no tools) that
answers a tool call with a jev verdict and, when the verdict is a refusal above `threshold`, blocks
the call. The block is written by Hermes as the call's *tool result*, so nothing in the transcript is
rewritten: the request prefix stays byte-identical and the provider's prefix cache keeps hitting.
This is the cache-optimal half of the "chrono-break" idea — a refusal is appended, not rewound.

## What it does per call

1. `pre_llm_call` records the turn's user message as the task text (`state.task`). It returns `None`,
   so it injects nothing and never changes a message. It also resets the per-turn strike counter when
   `turn_id` changes.
2. `pre_tool_call` runs a free deterministic gate first: the tool must be in `tools` (default
   `terminal`, `write_file`, `patch`, `execute_code`) and, for `terminal`, the first word of the
   command must not be a read-only verb (`ls`, `cat`, `grep`, `git`-free set in `_READ_ONLY_COMMANDS`).
   Anything else returns `None` at ~0.2 ms with no network.
3. Otherwise it builds a three-field state (`task`, `call` = the JSON of tool+args, `recent_calls` =
   the last 6 calls in the session) and asks jev exactly one `choice` question, options
   `proceed` / `refuse-destructive` / `refuse-off-task` / `refuse-repeat`.
4. A refusal pick at or above `threshold` returns `{"action": "block", "message": …}`; Hermes turns
   that into `{"error": "...REFUSED by jev-tool-gate..."}` as the tool result. Any other pick returns
   `None` and the call runs.

## Failure and blast-radius limits

- **Fail-open, always**: exception, timeout, non-zero exit, unparseable output, unknown pick, a
  missing binary, or no recorded task all return `None`. Logs at debug only.
- `pre_tool_call` is Hermes's single fail-closed hook, so the `jev` subprocess is hard-killed at
  `timeout_ms` + 0.5 s grace and the hook stays far inside `plugins.hook_callback_timeout` (30 s).
- **Strike limit** `max_blocks_per_turn` (default 2): after two blocks in one user turn the gate stays
  shut, so it can never deadlock a turn.
- **Cost cap** `max_calls_per_session` (default 40) bounds the jev round trips in one session.

## Measured on this box (2026-09-19, real jev 1.13.0, real Hermes 0.21.2)

Live session `20260919_144926_94e9b0` (`hermes -p default chat --in …/demo-ws -c jev-gate-demo`),
turn 2 (`ok go`, confirming an already-printed `rm -rf build dist stale.txt` cleanup plan):

- jev refused the same `rm` call **twice**, both times appended as the tool result:
  - `terminal -> refuse-destructive (p=0.81)`
  - `terminal -> refuse-repeat (p=0.94)`
- The third attempt went through (strike limit), the run finished, and the model itself reported the
  refusal. `sessions.rewind_count = 0`; no message was edited.
- Per-API-call prefix cache around the refusals (`agent.log`): 94%, 98%, 97%, then 15%, 99%. The 15%
  is **not** the gate — low-cache calls are common on this route without any gate (100 of 1983 calls
  in `agent.log` read under 50%; reads cluster on ~20480/16384-token block values), i.e. a provider
  prefix-cache shard miss, and the very next call reads 99% again with the refusal still in context.

Controlled A/B on the same route (`deepseek/deepseek-v4.1-flash` via `ai-gateway`, 6059-token prompt
built from real repo files, identical prefix re-sent):

| request | cached_tokens | cost |
|---|---|---|
| first send (warm) | 0 / 6059 | $1.84e-03 |
| identical prefix re-sent | **6016 / 6059 (99.3%)** | $6.82e-05 |
| same prefix with one line inserted mid-way | **0 / 6075 (0%)** | $1.84e-03 |
| identical prefix re-sent again | 6016 / 6059 (99.3%) | $6.82e-05 |

Append = 99.3% hit and ~27x cheaper; a mid-prefix edit = 0% hit and full re-prefill. That is the
whole cache argument for the refusal shape over a scrub/rewind, measured on the live route.

## Known limitation (the reason it ships off)

The task text is only the *last* user message. On a terse continuation (`ok go`) a legitimate,
user-confirmed cleanup reads as off-task/destructive and is refused — which cost that turn three extra
API calls before the strike limit let it through. Judging needs the turn's *plan*, not just its last
line. Until that is fixed the plugin stays out of `plugins.enabled`; enable it per session with

```
hermes config set --force plugins.enabled '["jev-skill-router", "cwd-command", "jev-tool-gate"]'
```

or flip `plugins.entries.jev-tool-gate.settings.enabled` false to keep it installed but inert.

## Files

- `__init__.py` — the whole plugin (free gate, one jev `choice` call, block directive, limits).
- `plugin.yaml` — manifest and `config_schema`.

Installed live by the module at `.hermes/plugins/jev-tool-gate/` (see `../default.nix` `gateFiles`).
