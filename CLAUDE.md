# NixOS Configuration

## Setup

NixOS-only repo using bayt for user file management.
Always work from `~/nixos` root directory.

## Directory Structure

### `hosts.nix`
Top-level host inventory. Each host is composed from semantic module domains plus a selected profile via `recursivelyImport`.

### `recursivelyImport.nix`
Recursive module loader. Imports module `.nix` files from folders, ignores non-`.nix` helpers such as `.nixlib`, and skips `data/` and `npins/`.

### `modules/`
All reusable NixOS module content lives here.
- `modules/core/` — universal system and user foundations
  - `boot/` — bootloader and kernel settings
  - `system/` — global system defaults, nix settings, environment
  - `hardware/` — reusable hardware modules
  - `networking/` — base networking configuration
  - `security/` — security modules
  - `services/` — always-on system services not tied to a desktop session
  - `user/` — shared user identity, core paths, shell-neutral defaults, appearance options, session config
  - `virtualization/` — virtualization modules
- `modules/desktop/` — desktop stack
  - `session/` — session plumbing, desktop integration services, GUI defaults, UI, and theming
  - `apps/` — GUI applications and app-specific system glue
- `modules/shell/` — interactive shell environments and terminal tooling
- `modules/tools/` — CLI tools and developer-facing utilities
- `modules/user-services/` — user-scoped services such as SSH agent and Syncthing
- `modules/dev/` — development environments and AI tooling
- `modules/gaming/` — gaming platforms, launchers, and per-game tweaks
- `modules/profiles/` — reusable profile layers selected per host

### `hosts/`
Per-machine leaf modules only.
- hardware configuration
- impermanence/home rollback
- host-specific quirks
- install-only helpers such as disko live under `data/`

### `lib/`
Shared helpers that are not NixOS modules.
- `lib/generators/` — custom format generators

## Conventions

### Composition
Host composition happens in `hosts.nix`, not inside host leaf modules.

### Module Files
Every `.nix` file outside `data/` and `npins/` must be a valid NixOS module.
Private helper expressions that are not modules should use `.nixlib` or another non-`.nix` extension.

### Profile Files
Profiles live under `modules/profiles/` and are split by concern: `identity.nix`, `defaults.nix`, `paths.nix`, `ui.nix`, `programs.nix`, `dev.nix`, `gaming.nix`, `shell.nix`, `tools.nix`, `services.nix`.

### Data Files
Avoid `data/` for module-local implementation helpers.
Prefer semantic directories such as `assets/`, `templates/`, `colorschemes/`, or `plugins/`, and use `.nixlib` for non-module Nix expressions that should not be auto-imported.
Keep `data/` only for genuinely external or host-local payloads that need a subtree without participating in the module graph.

Examples:
- `modules/dev/claude-code/assets/`
- `modules/desktop/session/theme/wallust/templates/`
- `modules/desktop/apps/browsers/userChrome.css`

## Workflow

Uses bayt. Clone external repos to `~/nixos/tmp/`.
All packages are system-level via NixOS modules.

```
git add -> alejandra . -> nh os switch --dry -> nh os switch -> TEST -> git commit && push
```

Only commit after formatting, successful evaluation/switch, and manual testing.

## Bayt Syntax

```nix
bayt.users."${config.user.name}".files."path" = {
  generator = lib.generators.toFormat {};
  value = {};
};
```
