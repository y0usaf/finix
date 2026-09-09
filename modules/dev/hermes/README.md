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

Profiles, models, skills and memory are managed through Hermes itself. Existing
profile data and conversations are not deleted by this source cleanup.

## Applying the change

Build the desktop system with:

```sh
nix build path:.#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel --no-write-lock-file
```

Activate through the normal Finix deployment workflow, then quit and reopen
Hermes. A source edit or build alone does not update the running app.

The default live profile uses a short SOUL, built-in memory, disabled curator and
background review, and a small enabled skill catalog. Model, compaction and
specialist bot configurations are preserved. These are mutable Hermes settings,
not a Finix reconciliation policy. Existing conversations can retain older
instructions; use new conversations after restarting the updated app.

The pre-ablation default config, SOUL and Mnemosyne plugin link are backed up
under `~/.hermes/backups/pre-ablation-20260909-114854/`. Mnemosyne data and all
named bot profiles remain on disk.
