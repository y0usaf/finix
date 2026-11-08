# finix

Configures y0usaf's machines from one Nix flake.

The hosts run [finix](https://github.com/finix-community/finix), NixOS-style modules on the finit init system instead of systemd. The repo owns system integration and user configuration; the programs themselves live in their own repos and come in as flake inputs.

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
nhs                    # build this host with iets, then nh os switch
nhs --nix              # same, evaluating with nix instead of iets
nhs -u                 # nix flake update first; -d for a dry run
nh os switch .         # plain nh, from ~/finix
finix-switch           # build the committed HEAD, switch under the shared agent lock, print JSON
nix build --no-link .#nixosConfigurations.y0usaf-desktop.config.system.build.toplevel
nix flake check        # builds every host, plus the lint and codegen checks
nix run .#lint         # strictix lint; `nix run .#lint -- fix` applies fixes
nix fmt                # alejandra
```

`nhs`, `nhd`, `nhu` and `nhc` are shell functions from `modules/tools/nh.nix`. Build with `--no-link` so no `result` link lands in the repo.

Other machines:

```sh
nix run .#finix-server-persistent-deploy -- [host] [test|boot|switch]   # default: server, test
nix run .#finix-frame-deploy -- [host]                                  # default: frame-nixos.home
```

The Frame deploy needs qemu aarch64 binfmt registered and the Frame booted from its shared pool; it says which is missing.

## Tools in the flake

| Command | Does |
| --- | --- |
| `nix run .#drift -- HOST [OTHER]` | list a host's packages, services and persisted paths, or diff two hosts |
| `nix run .#p4g-setup -- prepare\|status\|install\|disable` | install or remove the Persona 4 Golden mod pack |
| `nix run .#omp-box-selftest` | test the omp-box microVM |
| `nix run .#glsl-gate -- ORIGINAL GENERATED` | check two GLSL files are the same program |

## Dependencies

- Nix with flakes.
- SSH access to y0usaf's private GitHub repos (several inputs are `git+ssh`).
- Local checkouts under `~/dev/developing/`: `tern-script`, `boar-rs`, `omp-bot`, `tern-ekko`, `tern-ozette` and `tern-scratch` are `git+file` inputs.

The main inputs are nixpkgs, finix, [manzil](https://github.com/y0usaf/manzil) (writes the user's home files), [strictix](https://github.com/y0usaf/strictix) (lint) and nix-on-droid. `flake.nix` lists the rest.

## Config it reads

The flake reads only Nix, plus the npm and Cargo lockfiles in `locks/`, which `npm install` and `cargo update` rewrite in place.

| Variable | Read by | Effect |
| --- | --- | --- |
| `NH_FLAKE` | `nhs`, `nh` | flake path, set to `~/finix` |
| `FRAME_REPO` | `finix-frame-deploy` | deploy a local steam-frame-nixos checkout instead of the pinned input |
| `VERCEL_ACCOUNT` | `vercel` | `personal` or `work`; otherwise the git `origin` owner picks the login |

## Layout

- `flake.nix` holds the inputs; `modules/outputs.nix` builds every output with plain functions and lists each host's modules.
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
