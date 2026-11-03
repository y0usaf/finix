# omp transcript presentation

In Tern, omp's transcript gives each thing one level of attention:

- **The answer** that ends a turn sits in a bubble on the left, opposite your messages on the right.
- **Work** folds into one row per stretch of steps. A row leads with the sentence the model wrote before those steps, then the step count and time; a row with no such sentence reads **Worked for …**. It stays open while it runs and folds when the next sentence or the answer arrives. Folded, the sentence is cut to one line; open, it wraps in full with its links. Open the row for the model's reasoning, any further paragraphs and each step; open a step for its code and output.
- **Turn stats** (time, tokens, cost under each answer) are hidden by **hide turn stats** in Tern's UI options block; untick it to bring them back.
- **Chat looks** are three ticks in the **omp chat** group of Tern's UI options: **Grok chat** (unboxed 15/22 px answers, a small bubble for your messages, a 720 px column, thinking, turn stats and the composer meters hidden, advisor notes as one dim "Advisor · …" line), **frosted bubbles** (your message and the composer frosted) and **no streaming** (an answer shows once it is written). They style the `omp.chat.msg`, `omp.chat.dock` and `omp.chat.advice` blocks around messages, the composer and advisor notes, so they reach every omp chat, bots included.
- **Failures** show as a red count on their row. A failed step stays listed under the folded row only when the turn ended on it.
- **Notices** from omp and extensions keep their own small rows, inside a work row when they land mid-work.

The pieces:

- [code-mode.ts](code-mode.ts) asks for a short title on every eval cell, which becomes the step's name.
- [compact-eval.ts](compact-eval.ts) folds eval steps to their title, drops language badges, and names untitled steps after the tool they call or their first line.
- [work-fold.ts](work-fold.ts) builds the rows. Your messages, skill and collab prompts, `!`/`$` commands and compaction markers start a new stretch.
- The answer bubble, the quieter sentences, the rail under an open row and the chat looks are tweaks in the [UI Menu](../../../tools/tern/config/plugins/ui-menu/window.luau) Tern plugin.

omp is pinned by Nix, so its startup update check is off.

Restart existing omp sessions after changing the extensions; `tern plugin reload` picks up the stylesheet. They use omp's exported UI internals and Tern's Reader classes; after upgrading either, check a running turn, a finished turn, an opened row, a notice between two steps and a success → failure → success turn.

# OptChat memory

Every omp chat, on the host and in the box, shares one memory built the way Victor Taelin's OptChat describes: an append-only log of messages, a binary tree of summaries of at most 512 bytes, and a view of 64–128 KB that covers the whole log, detailed for recent messages and coarse for old ones.

- [optchat/extension.ts](optchat/extension.ts) logs the user's messages and the agent's replies of each main chat (TUI or RPC mode, with a session file) to `~/.local/state/optchat/log/<session>.jsonl`, one writer per file. Tool calls, print-mode runs, subagents and the advisor are not logged, nor are turns from before a chat loaded the extension. A chat gets the view ahead of its first message and keeps it frozen, so the prompt cache holds. omp still compacts the chat with its own summary, which keeps its tool work and older turns, and the extension then takes a fresh view. The `zoom`, `date` and `recent` tools read the memory.
- [optchat/service.ts](optchat/service.ts) runs as the `optchat` finit service, a headless omp. It merges the session logs into `main/`, has Luna 6 (`openai-codex/gpt-6-luna`, through the omp-box proxy so Crest picks the login) write the summaries into `tree.jsonl`, and writes `view.txt`. Every summariser call is a line in `spend.jsonl`; `optchat-spend` totals them per day at list price.
- The service shares `~/.local/state/optchat` with the box through `omp-box add`. The box reads its omp config at boot, so box chats join after the box restarts.
- `OPTCHAT_DIR` picks the store for both the extension and the service; without it they use `~/.local/state/optchat`, so the same code serves the shared store and every bot store.
- With `OPTCHAT_BOT` set, the store is one bot's own memory, used by omp-bot (`~/dev/developing/omp-bot`) for every bot. The memory is the bot's whole context: each model call gets the rules in `OPTCHAT_RULES` word for word, then the view, then the latest turns raw, tool calls included, up to `OPTCHAT_RAW` bytes (128 KB), cut back to half and re-viewed when they outgrow it. A bot's first start logs the conversation it already has; its `pin_rule` tool appends a standing rule to the rules file. With `OPTCHAT_BOTS`, the folder holding each bot's `NAME/optchat`, `zoom`, `date` and `recent` take an optional `bot` to read another bot's memory read-only, and `memories` lists the bots that keep one. The service tells the summariser it writes one bot's memory. [../omp-bot.nix](../omp-bot.nix) points omp-bot at this directory with `OMP_BOT_OPTCHAT`; it is the same store path as the extension in the omp config, so a bot that loads your extensions loads it once.

# /cwd

[cwd.ts](cwd.ts) adds `/cwd` to every omp chat: `/cwd` alone shows the working directory as a notice, and `/cwd DIR` moves the chat there by running omp's `/move DIR`, with the same directory completion. Moving works in the TUI only, as `/move` does.

# Secrets

[secrets/secrets.ts](secrets/secrets.ts) lets every omp chat use a secret (an API key, a token) without the value reaching the model, the session file or OptChat.

- The chat asks with its `secret` tool, naming the secret, saying why and optionally how long it should last (`30m`, `12h`, `7d` or `never`; default 24 hours), and waits up to 10 minutes. The ask shows as a notice; `omp-secret` alone lists every open ask and the secrets set.
- `omp-secret NAME [--bot BOT | --user] [--ttl TTL]` reads the value with the typing hidden (or from stdin when it isn't a terminal) and stores it for whoever asked; `list` shows names, scopes and expiry, never values, and `forget NAME` deletes one. The chat's `secret` tool can list and forget its own too.
- The chat uses a secret by writing `$SECRET_NAME` in a bash command. The `tool_call` hook reruns the command, unchanged, through `omp-secret run` as a heredoc: that decrypts only the secrets the command names, sets them for that one command (run with `bash -c`, so a `cd` in it doesn't last) and replaces each value in its output with `[SECRET_NAME]` as it streams. A command naming a secret the chat doesn't hold is blocked and told to ask. Every tool result is also scrubbed of every value the chat holds (or held earlier in the run) in the `tool_result` hook, before it reaches the model, the session file or OptChat, and the `context` hook scrubs what the model is sent. Live progress of a command that prints a value without naming it is not scrubbed while it streams; its result is. omp runs as you, so a chat could still smuggle a value out in another form (base64, say); redaction catches the exact value only.
- Secrets live in `~/.local/state/omp-secrets`, persisted across reboots: each one age-encrypted to `secrets.key` (mode 600, made on first use) with its expiry and reason beside it. A chat started by omp-bot (`OMP_BOT_NAME` set) keeps its secrets in `bots/NAME/`, every other chat shares `user/`, so a bot can't use your secrets or another bot's by name. That is a boundary against mistakes, not an attack: everything runs as you and can read the key.
- age rather than the kernel keyring because secrets should outlive a reboot, and the keyring a service-run bot reaches isn't reliably the one your terminal stored into.
- omp-bot loads this and [cwd.ts](cwd.ts) into every bot through `OMP_BOT_CWD_EXTENSION` and `OMP_BOT_SECRETS_EXTENSION` in `~/.config/omp-bot/env`, even when the bot's own extensions are off. omp-box chats don't load it.
