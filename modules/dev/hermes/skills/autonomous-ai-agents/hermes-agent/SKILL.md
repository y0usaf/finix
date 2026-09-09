---
name: hermes-agent
description: "Use when configuring or troubleshooting Hermes Agent."
version: 3.3.0
---

# Hermes: compact operating guide

Use for Hermes configuration, setup, extension, operation, and troubleshooting—not ordinary tasks merely running inside Hermes.

## Invariants
- On this installation, make setup changes declaratively in `~/finix/modules/dev/hermes/` first. Read that module's README, preserve unrelated work, and test before activation. Live-only edits are not a durable deliverable. Keep credentials, sessions, and memories out of the Nix store; ask before changing another profile or deploying a full system.
- Check the live CLI/schema/source before inventing commands. Official current documentation: https://hermes-agent.nousresearch.com/docs/ . For an unlisted feature, fetch `/docs/llms.txt` and open only the relevant page; absence here does not mean unsupported.
- Resolve the active home from `$HERMES_HOME` or `get_hermes_home()`. Default is `~/.hermes`; other profiles are separate. Do not modify another profile without authorization.
- Settings: `hermes config set KEY VALUE`; never hand-edit config.yaml. Secrets belong in `.env` or the credential store, never config.yaml. Do not print credentials.
- Preserve cached prefixes: do not mutate past messages, system prompts, or toolsets mid-conversation except required compression. Toolset changes belong in new sessions.
- Preserve role alternation; tool results may repeat, user/assistant roles must alternate.
- Verify consequential operations with read-back/tests. A config write is not proof of live behavior.
- Load this entry once while it remains in context; load a specific reference only when needed. Reload if pruned, not simply because another tool call occurred.

## References: select only the relevant file
Use `skill_view(name='hermes-agent', file_path='references/FILE.md')`.

| Task | FILE |
|---|---|
| CLI commands / slash commands | cli-reference / slash-commands |
| Providers, OAuth, API keys | providers-and-models |
| Settings, tools, voice | configuration |
| Project instruction files | project-context-files |
| Approvals, redaction, privacy | security-privacy |
| Delegation, cron, curator | background-systems |
| MCP / webhooks | native-mcp / webhooks |
| Themes / skins | themes |
| Desktop plugins / TUI widgets / pets | desktop-plugins / tui-widgets / petdex |
| Debugging / Windows | troubleshooting / windows-quirks |
| Hermes source changes | contributor-guide |
| Child concurrency cap diagnosis | delegate-task-concurrency-diagnosis |
| Third-party Nous Portal OAuth | portal-auth-for-third-party-apps |

Append `.md` to each FILE. For bots and messaging use docs `/user-guide/bot-mode` and `/user-guide/messaging`.

For subprocess spawning examples, surface overview, and the extended guide, read `references/detailed-guide.md` only when that material is needed. Existing templates remain available under `templates/`.

## Key locations and commands
- `state.db`: canonical SQLite sessions; `sessions/`: routing/dumps; `logs/`: diagnostic logs.
- `config.yaml`: settings; `auth.json` and `.env`: credentials; `skills/`: procedural knowledge.
- `hermes --help`, `hermes <command> --help`: verify live syntax.
- Theme changes: apply with `hermes config set display.skin NAME`; edit active colors with `hermes skin set KEY HEX`, not a fork of default. Read the themes reference first.
- Named-agent handoffs: discover live profiles and follow the current conversation's messaging instructions. Do not launch an extra model merely to inspect local data.
