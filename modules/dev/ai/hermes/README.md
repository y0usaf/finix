# Hermes

Finix's stock build of upstream Hermes, plus the slope-line delegation plugin,
bundled skills, and the default-profile behavior policy. This directory is the
whole module: there is no separate `hermes-tools` repository or flake input.
Finix pins upstream `hermes-agent` (and `hermes-desktop-terminal`) and builds it
unmodified; the desktop owns its backend, and the CLI and desktop share
`~/.hermes`.

## Layout

- `packages.nix` / `bot-packages.nix` -- `callPackage` builders for the Hermes
  CLI, the desktop, and the Bots Mod plugin. The caller supplies the upstream
  pin, the plugin source, and `apiKeyFile`.
- `default.nix` -- installs the apps, `slope`, the slope-line plugin, skins, and
  the desktop entry.
- `remote-gateway.nix` -- tailnet-exposed `hermes serve`.
- `behavior.nix`, `behavior-settings.json`, `SOUL.md` -- default-profile policy.
- `skills.nix`, `skills/`, `skills/disabled.json` -- bundled skills and policy.
- `plugins/slope-line/` -- the `line_task` delegation plugin (dispatches to `line`).
- `load-credentials.sh` -- runtime AI Gateway key loader for the CLI/desktop.
- `skins/abyss.yaml` -- themes CLI, TUI, and desktop together.

## Build

`packages.nix` builds the pinned upstream `hermes-agent` and desktop as-is. It
adds only install-time wiring:

- the CLI and desktop wrappers source `load-credentials.sh` for the runtime AI
  Gateway key (`HERMES_API_KEY_FILE`), and the CLI wrapper unsets
  `_HERMES_GATEWAY` so `--in` children get their own working directory;
- the pinned Bots Mod plugin (`plugin.js` + `LICENSE`) is copied and smoke-tested
  (`node --check`, `roster.test.mjs`, `shelf.test.mjs`); it ships through the
  desktop's `desktop-plugins/` door, not as a source patch;
- the upstream `nix/desktop.nix` text is rewritten for finix's nixpkgs: the
  electron-headers sha256 is set to our electron version and the relative
  asset/desktop-entry paths are made absolute. The Hermes source is not patched.

## Rebuild

`nhs` is Finix's alias for `GC_DONT_GC=1 nh os switch` (see `modules/tools/nh.nix`).
After a switch, quit and reopen Hermes; a build alone does not update the running
app.

## In-build check

One check runs inside the Nix build so a broken wrapper fails the build instead
of silently drifting:

- `test_cli_child_cwd.py` runs in `hermesFull`'s `postFixup` with the packaged
  venv Python. It launches the wrapped `hermes` CLI and asserts that `--in`
  children do not inherit the gateway's `TERMINAL_CWD`, guarding the
  `_HERMES_GATEWAY` unwrap in `packages.nix`.

Re-run it by hand after changing the wrapper:

```sh
# supply the packaged venv python and the wrapped hermes bin
<packaged-venv>/bin/python3 modules/dev/ai/hermes/test_cli_child_cwd.py <wrapped-hermes>
```
