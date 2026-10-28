# Repository layout

This repository configures y0usaf's machines on finix: it owns system
integration and user configuration, not application implementations.
Headlong operations live in `~/dev/developing/headlong-ops`. A project that
stays external comes in as a flake input. Keep runners, application patches,
reusable skills and their tests with the module or project that owns them.
Runtime state and credentials stay outside the source tree and the Nix store.
Don't create root-level `nix/`, `tests/` or `previews/` directories.

`flake.nix` holds the inputs and hands them to `modules/outputs.nix`, which
builds every output with let bindings and plain functions. No module system
runs at flake level.

A host is a list of modules, and the `hosts` attrset in `modules/outputs.nix`
holds each host's list. Every host loads `modules/finix/common.nix`,
`diagnostics.nix` and `sudo.nix`: the settings all hosts share, boot
diagnostics and sudo. The graphical hosts load every `.nix` file under the
graphical roots (`core`, `desktop`, `dev`, `gaming`, `shell`, `tools`,
`user-services` and `hosts/common`), so each of those files is a module; the
server names its modules one by one: its role in `modules/server/`, its host
files and a few program modules.
`modules/hosts/common/` is the graphical role. Its system layer,
`modules/finix/desktop/`, is imported from `graphical.nix` instead of loaded
as a root. Roots load in path order, and a list option merges in load order,
so moving a module moves its packages, kernel modules and udev rules within
those lists and changes the build.

Loading a module turns it on. A module declares an option only when the hosts
that load it need different values, or when three or more modules read the
value. Anything else is written where it is used, and a helper one module
uses is a let binding in that module.

A program's module owns its packages, settings, dotfiles and persisted paths,
and decides from hardware facts such as `hardware.nvidia.enable`, never from
the hostname. A program that needs only its package is a line in its
category's package list: `core/packages.nix`, `desktop/packages.nix`,
`dev/packages.nix`, `tools/packages.nix`, `gaming/core.nix` or
`server/packages.nix`. `tools/tmux.nix` stays a module of its own because the
server loads it by name. Persisted paths no module owns go in
`modules/hosts/common/persist.nix` when both graphical hosts keep them, and in
the host's `config.nix` when only that host does.

Each host directory under `modules/hosts/` holds what is true of that machine
alone, in two files beside its keys and other non-Nix files.
`hardware-config.nix` holds facts about the machine: disks, btrfs subvolumes
and mount options, boot, kernel and initrd modules, firmware, GPU and
displays. `config.nix` holds the host's choices: hostname, open ports,
host-only persisted paths, services, and where it departs from its role.
`modules/hosts/shared.nix` holds the machinery the hosts share, a btrfs mount
builder and the nftables ruleset, which each host calls with its own values;
hosts import it, and no host list loads it. `modules/hosts/android-phone/` is
the nix-on-droid phone.

`modules/hosts/steam-frame/` is the Steam Frame, which runs NixOS, not finix.
The external steam-frame-nixos project supplies the Frame itself as
`nixosModules.default`, pinned as the non-flake input `steam-frame-nixos`;
`nix flake update steam-frame-nixos` moves it, and `FRAME_REPO=<checkout>`
deploys a local checkout instead. Everything personal about the Frame lives
here. `config.nix` holds the host's choices: the SSH keys, the storage pool's
UUID, the project's optional WiVRn client and framecorder, Stremio in Steam's
FHS environment, the Beat Saber mods, `tools/git.nix` and `tools/tmux.nix`,
and files linked with manzil; `bolo.nix` runs bolo on the CPU and fetches its
speech model at boot into the big home partition, out of the small root;
`mado.nix` runs mado-view whenever SteamVR runs, so the headset shows the PC's
mado stream. `deploy.nix` builds `finix-frame-deploy`, which builds a NixOS
system from the project's nixpkgs and module, manzil's NixOS module,
`config.nix`, manzil's static aarch64 linker (cross-built on this machine) and
bolo's and mado's aarch64 packages (`--impure`), then copies and switches the
Frame over ssh. The rest of the closure builds under the qemu aarch64 binfmt
handler; `finix-frame-deploy` names the command that registers it when it is
missing.

`omarchy.nix` runs the desktop layer of Omarchy 4.0.4 (Hyprland and its
QuickShell shell) as a SteamVR overlay: a nested Hyprland is a client of a
second gamescope (`--backend openvr --expose-wayland`), and Aquamarine needs
the three fixes in `omarchy/aquamarine-gamescope.patch`. Nothing starts it:
`systemctl --user start omarchy` over SSH does, and it stops whenever SteamVR
restarts. Its `ExecStopPost` removes what Hyprland and Quickshell leave in
`$XDG_RUNTIME_DIR`; Omarchy's own state stays in the home. Its menu actions
act on the host's services. Quickshell 0.3.1 ignores a NetworkManager profile
without `mode=infrastructure`, which steam-frame-nixos's
`tools/wifi-from-nm.py` writes. On the Frame it drew its bar, menu and a
terminal and ran 15 minutes on the live session without an error; how it looks
in the headset, shortcut keys, theme switching and the audio, Bluetooth and
power actions are unverified, and screen recording, the screensaver and the
lock screen are unavailable.

`beat-saber.nix` installs BeatMods mods into Beat Saber by name, from
`frame.beatSaber.mods` in `config.nix`; BSIPA and each mod's dependencies come
along. `beat-saber/beatmods.json` pins every verified mod for one game version
with hashes, `beat-saber/lock.sh <game version>` regenerates it, and a name
not in it fails the build. BeatMods has mods for 1.44.1, so the game needs
Steam's `1.44.1_legacy` branch, and its launch options must be
`/run/current-system/sw/bin/beat-saber-mods %command%`. Each launch copies the
declared set into the game folder, deletes files of the previous set, and
starts the game with `WINEDLLOVERRIDES=winhttp=n,b` and `--no-yeet`.
`.nix-mods/` in the game folder holds the unpatched
`UnityEngine.CoreModule.dll` BSIPA patches and the installed file list; a file
of yours a mod replaces is kept there too and comes back when the mod goes. An
empty list, or a game version the mods aren't for, restores the game on the
next launch, keeping `UserData`, `Logs` and your own files. Problems go to
Steam's journal (`journalctl --user -u steam | grep beat-saber-mods`). Under
Proton 11.0 (ARM64) the mods load and BeatSaverDownloader downloads songs, but
starting any song fails: InvalidCastExceptions in Zenject injection and
MonoMod's struct-return glue freeze the level.

`modules/finix/sudo.nix` configures sudo itself and takes only the privileges
provider from finix's sudo module. Leave `programs.sudo.enable` off: it also
installs the non-setuid sudo binary, which shadowed the
`/run/wrappers/bin/sudo` wrapper on PATH (c9a60e8c).

`modules/finix/tailscale.nix` runs tailscaled on the server and, through
`graphical.nix`, on the graphical hosts. It makes openresolv the owner of
`/etc/resolv.conf` so that tailscaled (openresolv mode), dhcpcd and
NetworkManager share it: tailscaled goes first with MagicDNS, DHCP servers
follow and public servers come last with a one-second timeout, so DNS survives
tailscaled being down. tailscaled starts after the `resolvconf` task because
it picks its DNS mode from the header that task writes. Hosts name each other
by MagicDNS. `tailnet.addresses` keeps the addresses of the places that need
one: the `rescue` and `rescue-root` ssh hosts, which must work when DNS is
broken, paseo's listen bind and the server's hosts aliases.

A directory holds a category or one module's assets. No file exists only to
import others or to set values another module owns, except
`modules/finix/desktop/default.nix`, whose import keeps the graphical role's
system layer at its place in that merge order.

Validate with `nix build --no-link`, so no result link lands in the repo.
