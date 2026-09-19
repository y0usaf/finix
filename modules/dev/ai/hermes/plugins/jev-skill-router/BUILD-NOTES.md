# jev-skill-router

A Hermes plugin (manifest_version 2, `provides_hooks: [pre_llm_call]`, no tools) that adds a
one-line, jev-derived skill hint to the *user message* each turn, and nothing else. Zero core
changes: it uses only the documented `pre_llm_call` hook, whose returned string is appended to the
user message by `agent/turn_context.py::_collect_pre_llm_call_context`.

## What it does per turn
1. **Free gate** (no network): tokenize the user message and score it against the live skill
   catalogue (`tools.skills_tool.skills_list` -> name/description/category) with an idf-weighted
   token overlap. Bail out (return `None`, ~0.2 ms) on an empty message, a `/slash` command, a bare
   greeting, or a message with no lexical candidate.
2. **One jev call, only when the gate fires**: build a document (`state.routing_note`,
   `state.skill_index` = the candidate `NAME - DESCRIPTION` lines, `state.user_message`) with one
   `choice` question whose options are the candidate names (+ `none-of-these`), and run
   `jev ask - --json --timeout <ms>` with the document on stdin. The CLI resolves its own key file;
   no key is ever passed, logged, or printed here.
3. **Output**: if jev picks a real candidate, return
   `Likely skill for this turn (jev): NAME - load with skill_view('NAME').` Otherwise `None`.
4. **Fail-open, always**: any exception, timeout, non-zero exit, unparseable output, sentinel pick,
   or missing binary returns `None`; the turn proceeds untouched. Logs at debug only.

## Files
- `__init__.py` -- the whole plugin (gate + call + hint).
- `plugin.yaml` -- manifest and `config_schema`.

Installed live by the module at `.hermes/plugins/jev-skill-router/` (see `../default.nix`
`routerFiles`); enabled by `plugins.enabled` in `../behavior-settings.json`.

## Knobs (`plugins.entries.jev-skill-router.settings.*`, read via `ctx.get_config`)
- `enabled` (bool, default true) -- master switch; false makes the hook inject nothing.
- `jev_bin` (str, default `/home/y0usaf/dev/developing/jev/jev-cli/result/bin/jev`).
- `timeout_ms` (int, default 2500) -- jev request timeout; the subprocess is hard-killed at this plus
  0.5 s grace, so a turn is never delayed past that bound.
- `min_candidates` (int, default 3) -- open the gate when at least this many skills lexically match.
- `max_candidates` (int, default 12) -- cap on candidates sent to jev.

## Deviation from the build spec (stated)
The spec's gate is "at least `min_candidates` candidates with nonzero score". On the live
34-skill catalogue the VOD message yields exactly **one** lexical candidate, so a pure
`>= min_candidates` gate would never route it. The gate therefore also opens on a **single lone
candidate** (`len == 1`); `min_candidates` still governs the ambiguous multi-candidate case. Cases
(iii)/(iv) stay closed because they have zero lexical overlap.

## Disable
- Runtime: `hermes config set --force plugins.enabled '["cwd-command"]'` (drop it from the list), or
  set `plugins.entries.jev-skill-router.settings.enabled` false.
- Declarative: remove `"jev-skill-router"` from `plugins.enabled` in `../behavior-settings.json`.
  The hook then injects nothing without any other change.

## Measured overhead (this box, real catalogue)
- Gate (both firing and non-firing): **~0.15-0.2 ms**.
- Non-firing turn adds ~0.2 ms and no network.
- jev round trip: **~0.38-0.40 s** warm; ~0.56 s on the first (cold node spawn) call.
- Gate hit rate on the four spec cases: 2/4 fire (the two skill-shaped messages), 2/4 stay closed.

## Decision (2026-09-19): plugin, not upstream-native

**Verdict: this stays a plugin in `~/finix`. No upstream issue/PR is warranted.**

1. *No missing core surface.* The mechanism is already expressible through documented core
   contracts, so an "upstream" change would add no capability — only move where the same
   behaviour is configured. Verified against the live 0.21.2 source: `pre_llm_call` is in
   `hermes_cli/plugins.py::VALID_HOOKS`; `agent/turn_context.py::_collect_pre_llm_call_context`
   joins every string / `{"context": ...}` return into the user message; the hooks docs list
   `pre_llm_call` kwargs (`user_message`, `conversation_history`, `session_id`, `turn_id`, ...).
   The same event is also carried by core shell hooks (`hooks:` config), and `pre_llm_call` is
   *not* in `SHELL_UNSUPPORTED_HOOKS`.
2. *Core already owns skill selection.* The system prompt carries the skill index and instructs
   the model to load matching skills from it. A second per-turn model call that picks a skill
   duplicates a responsibility core already assigns to the main model.
3. *The non-generic parts are personal.* `jev` plus its own key file, a hardcoded local binary
   path, and one private skill catalogue. Upstreaming would force either a hard dependency on an
   external CLI or a second billed inference call on every install's every turn. Neither belongs
   in core.
4. *The one more-native-looking alternative was assessed and rejected.* Rewriting it as a
   `hooks:` shell hook drops the plugin manifest but pays an out-of-process spawn **every turn**,
   routing or not, because the gate itself would run in the script. Measured on this box: bare
   `python3` spawn + JSON parse = **~16.2 ms median / 15.1 ms min**, vs the in-process gate's
   measured **~0.2 ms** — ~80x. A gate whose purpose is to avoid per-turn cost belongs in-process.

Consequence: the upstreamable unit, if anything, is the already-shipped hook contract
(`pre_llm_call`), not this router. No public posting was made (public actions are draft-then-approve).

## Restart caveat (unproven)
The plugins docs say to *restart Hermes* after dropping plugin files; no live plugin-reload path is
documented (`hermes plugins` has install/enable/disable/list/validate, no reload). A turn run in a
fresh `hermes` process picks the plugin up, and this was verified end to end. Whether the *already
running* desktop app re-reads `~/.hermes/plugins/` and `plugins.enabled` without a restart is
**not proven here** (restarting the desktop app is out of scope for this build).
