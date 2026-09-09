# Local Hermes

Finix packages the upstream Hermes CLI and desktop, loads the optional AI Gateway
key at runtime, and installs the Bots Mod desktop plugin. The desktop owns its
backend; CLI and desktop share `~/.hermes`.

The remaining standard patches provide session metadata, select Bots Mod,
suppress unsolicited bot greetings, and refresh visible unfocused panes.
There are no injected Python modules, prompt rewrites, profile reconcilers, crew
commands, archive automation, or Mnemosyne runtime in this module.

The optional [`hermes-project` runner](PROJECT-RUNNER.md) adds durable project
planning, isolated worker sessions/worktrees, verification, and independent
review on a private integration branch. It is a standalone command and does
not change the desktop's conversation loop or existing profile configuration.

Hermes setup changes belong declaratively in this module, not solely in live
`~/.hermes` files. `skills.nix` installs the compact skill entries and their
on-demand guides through Manzil. `skills/disabled.json` owns the default
profile's disabled-skill list, applied with the Hermes CLI at system activation.
Only that config key is reconciled; unrelated settings and named profiles are
preserved. Edit these source files first for future skill-policy changes.
Sessions, credentials, memories, and other runtime data remain mutable and must
not be copied into the Nix store. Existing conversations are not deleted.

## Applying the change

Build the desktop system with:

```sh
nix build path:.#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel --no-write-lock-file
```

Activate through the normal Finix deployment workflow, then quit and reopen
Hermes. A source edit or build alone does not update the running app.

The default live profile uses a short SOUL, built-in memory, disabled curator and
background review, and a small enabled skill catalog. Model, compaction and
specialist bot configurations are preserved. Those pre-existing settings remain
mutable; only the skill documents and disabled list above are reconciled so far.
Future setup changes should be encoded here rather than made live-only.
Existing conversations can retain older instructions; use new conversations
after restarting the updated app.

Skill-policy regression tests (Python with PyYAML and `hermes` on PATH):
`python3 modules/dev/hermes/test_skill_policy.py`. Tests use a temporary
`HERMES_HOME`, preserve unrelated config keys, and exercise idempotence.

The pre-ablation default config, SOUL and Mnemosyne plugin link are backed up
under `~/.hermes/backups/pre-ablation-20260909-114854/`. Mnemosyne data and all
named bot profiles remain on disk.
