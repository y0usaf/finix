# finix

Configures y0usaf's machines from one Nix tree pinned with `luin-pin`.

The hosts run [finix](https://github.com/finix-community/finix), NixOS-style modules on the finit init system instead of systemd. The repo owns system integration and user configuration; the programs themselves live in their own repos and come in as `.luin/pins.lock.json` inputs.

## Hosts

| Output | Machine |
| --- | --- |
| `nixosConfigurations.y0usaf-desktop` | desktop, CUDA |
| `nixosConfigurations.y0usaf-framework` | Framework laptop |
| `nixosConfigurations.y0usaf-server` | server: Forgejo, Attic, Syncthing, MediaMTX |
| `nixOnDroidConfigurations.default` | Android phone, via nix-on-droid |
| `finix-frame-deploy` | Steam Frame, which runs NixOS (from steam-frame-nixos) |

Every finix host boots with a tmpfs root: only paths on the persistence allowlist survive a reboot, from `/persist`.

## Build and switch

```sh
nh os switch                                                          # build this host with iets and switch
nh os switch --dry                                                    # build and diff without switching
NH_BUILD_BACKEND=nix nh os switch                                     # evaluate with nix instead of iets
nh os switch --impure "git+file://$HOME/finix?rev=$(git -C ~/finix rev-parse HEAD)"  # switch a committed rev only
ship [REPO] [--input NAME]                                            # check, push, bump .luin/pins.lock.json, switch committed rev, push finix
luin-pin update [NAME]                                                # update pins in .luin/pins.lock.json
nix build --no-link -f default.nix nixosConfigurations.y0usaf-desktop.config.system.build.toplevel
nix flake check --impure                                              # builds every host, plus strictix and e2e checks
nix run --impure .#lint                                               # strictix lint; `nix run --impure .#lint -- fix` applies fixes
nix fmt --impure -- .                                                 # alejandra
```

`nh` is configured via `NH_FILE` and `NH_ATTRP` from `modules/tools/nh.nix` and patched to build through `iets` by default. Plain `nh os switch` evaluates the working tree (`~/finix/default.nix`) and ignores `-H` in file mode; pass `-f ~/finix/default.nix nixosConfigurations.<host>` to target another host, or use `ship` / `git+file://...?rev=...` when you want a committed revision only. Build with `--no-link` so no `result` link lands in the repo.

### When Tomoe breaks

`tomoe-stable` is a second Tomoe installed beside the daily one: the last known-good build, started with the config that build was made with (never `~/.config/tomoe/init.lisp`), so the pair always loads together. When `tomoe` crashes you are back at the TTY shell that started it; when it hangs or comes up black, press Ctrl+Alt+F2 and log in. Then:

```sh
pkill -KILL -x tomoe   # only if the daily one is still holding the screen
tomoe-stable
```

It takes over the screen like `tomoe` does, and `tomoe` starts the daily one again next time. It is the `tomoe-stable` pin: a finix revision whose lock pins that Tomoe and whose config was generated for it, today finix `add5ffdb` with Tomoe `259c8ac`, the SBCL build that ran this desktop until the C core replaced it. Both lines move by hand, to a Tomoe that has been the daily desktop for a while. `nix build --no-link -f default.nix packages.x86_64-linux.tomoe-stable` builds the launcher on its own.

Other machines:

```sh
nix run --impure .#finix-server-persistent-deploy -- [host] [test|boot|switch]   # default: server, test
nix run --impure .#finix-frame-deploy -- [host]                                  # default: frame-nixos.home
```

The Frame deploy needs qemu aarch64 binfmt registered and the Frame booted from its shared pool; it says which is missing.

## Tools in the repo

| Command | Does |
| --- | --- |
| `nix run --impure .#drift -- HOST [OTHER]` | list a host's packages, services and persisted paths, or diff two hosts |
| `nix run --impure .#p4g-setup -- prepare\|status\|install\|disable` | install or remove the Persona 4 Golden mod pack |
| `nix run --impure .#omp-box-selftest` | test the omp-box microVM |
| `nix run --impure .#glsl-gate -- ORIGINAL GENERATED` | check two GLSL files are the same program |

## Dependencies

- Nix (with flakes enabled for the thin `flake.nix` shim).
- SSH access to y0usaf's private GitHub repos (several inputs are `git+ssh`).
- Local checkouts under `~/dev/developing/`: `tern-script`, `boar-rs`, `omp-bot`, `tern-ekko`, `tern-ozette` and `tern-scratch` are `git+file` inputs.

The main inputs are nixpkgs, finix, [manzil](https://github.com/y0usaf/manzil) (writes the user's home files), [strictix](https://github.com/y0usaf/strictix) (lint) and nix-on-droid. `.luin/pins.lock.json` lists the rest.

## Config it reads

The repo reads only Nix, `.luin/pins.lock.json`, and the npm and Cargo lockfiles in `locks/`, which `npm install` and `cargo update` rewrite in place.

| Variable | Read by | Effect |
| --- | --- | --- |
| `NH_FILE` | `nh` | entrypoint path, set to `~/finix/default.nix` |
| `NH_ATTRP` | `nh` | host attribute path, set to `nixosConfigurations.<host>` |
| `NH_BUILD_BACKEND` | `nh` | `iets` (default when on PATH) or `nix` |
| `FINIX_DIR` | `ship` | path to the finix checkout, defaults to `~/finix` |
| `SHIP_FINIX_REMOTES` | `ship` | space-separated git remotes to push finix to, defaults to `github forgejo` |
| `FRAME_REPO` | `finix-frame-deploy` | deploy a local steam-frame-nixos checkout instead of the pinned input |
| `VERCEL_ACCOUNT` | `vercel` | `personal` or `work`; otherwise the git `origin` owner picks the login |

## Layout

- `.luin/` holds the pinned inputs and loader; `default.nix` wires them into `modules/outputs.nix`, which builds every output with plain functions and lists each host's modules. `flake.nix` is a 1-line shim over `default.nix`.
- Loading a module turns it on. Graphical hosts load every `.nix` file under `core`, `desktop`, `dev`, `gaming`, `shell`, `tools`, `user-services` and `hosts/common`; the server names its modules one by one.
- `modules/hosts/<host>/` holds what is true of one machine: `hardware-config.nix` for hardware facts, `config.nix` for its choices. `modules/hosts/shared.nix` holds the mounts and firewall the hosts share.
- `omp-box/` is the microVM that boxed omp agents run in.

## Conventions

- A program's module owns its packages, settings, dotfiles (`user.files`) and persisted paths (`user.persist.directories`). It decides from hardware facts such as `hardware.nvidia.enable`, never from the hostname.
- A program that needs only its package is a line in its category's `packages.nix`.
- Persisted paths no module owns go in `modules/hosts/common/persist.nix` when both graphical hosts keep them, else in the host's `config.nix`.
- Declare an option only when hosts need different values or three or more modules read it.
- A file a module installs lives beside it in its own language and is referenced by path or read with `builtins.readFile`/`lib.importJSON`.
- `modules/hosts/steam-frame/beat-saber/lock.sh GAME_VERSION` rewrites `beatmods.json`, the BeatMods lock for one game version.
- Module order matters: list options merge in load order, so moving a module can change the build.
- Leave `programs.sudo.enable` off; its non-setuid sudo shadows the `/run/wrappers/bin/sudo` wrapper.
- Runtime state and credentials stay out of the repo and the store. Don't add root-level `nix/`, `tests/` or `previews/`.

## Manual steps

Some setup lives outside Nix and has to be done once by hand.

- **Vercel:** run `vercel-personal login` and `vercel-work login`, choosing the matching browser account, and check each with `whoami`.
- **Persona 4 Golden:** launch the game once in Steam, close it, then run `p4g-setup prepare` and `install` as the Steam user. `disable` returns to vanilla; backups go to `~/Games/P4G-CEP/backups/`.
- **Beat Saber (Frame):** switch to Steam's `1.44.1_legacy` branch and set launch options to `/run/current-system/sw/bin/beat-saber-mods %command%`.
- **Aniimo:** mods target Steam build 26426499; after a game update, re-pin `modules/gaming/aniimo/` against the new vanilla archive.
- **omp and Tern:** restart running omp sessions after changing their extensions; `tern plugin reload` picks up stylesheet changes.
- **Nix Userscripts:** `modules/desktop/apps/browsers/userscripts/` holds the userscripts LibreWolf publishes once `nixUserscripts` in that module is true. That needs the extension signed, plus its `ExtensionSettings` force-install entry; until then Violentmonkey keeps them.
