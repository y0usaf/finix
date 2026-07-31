# Drift audit — NixOS declarations vs the running finix desktop

Date: 2026-07-29. Host audited: `y0usaf-desktop` (running finix since
2026-07-17, commit `4a7bba07`). Nothing in this file has been fixed; it is a
record of what was found so it is not lost.

## Why this audit exists

The desktop's config lives in two module universes:

- `modules/` — NixOS modules (239 files)
- `finix/` + `hosts/y0usaf-desktop/finix/` — the OS that actually boots

`finix/compat-import.nix` bridges them by **whitelist**. It keeps five things:

    user   manzil   environment   fonts   services.udev.packages

Everything else — `boot`, `systemd`, `programs`, `networking`, `security`,
`nixpkgs`, `nix`, `users`, `hardware` — is silently discarded. No error, no
warning. A module that sets a dropped key still evaluates, still merges, and
does nothing.

Facts that live in dropped keys must therefore be **restated** on the finix
side. Two mechanisms are in use for that, and they produce very different
results.

## The two mechanisms

### Derived (works)

`hosts/y0usaf-desktop/finix/persistent.nix:30`

    persistCfg =
      ((import ../impermanence.nix) {})
      .environment.persistence."/persist";

Imports the NixOS file and reads its data at eval time. The ~250-entry persist
allowlist exists once. Adding a path to `impermanence.nix` reaches finix on the
next build; there is no second list to update.

Four divergences are hand-written and each is documented in place
(`persistent.nix:39-45`): `/etc/*` not bind-mounted (finix owns `/etc`), ssh
host keys read in place, `machine-id` copied by activation, `/root` bound by
task not fstab (upstream `escapePath` name collision).

Verified live — all correctly bind-mounted:

    /var/lib/bluetooth  -> /dev/nvme0n1p5[/@persist/var/lib/bluetooth]
    /var/lib/docker     -> /dev/nvme0n1p5[/@persist/var/lib/docker]
    /var/lib/btrbk      -> /dev/nvme0n1p5[/@persist/var/lib/btrbk]
    /var/lib/fwupd      -> /dev/nvme0n1p5[/@persist/var/lib/fwupd]

### Hand-copied (drifts)

`hosts/y0usaf-desktop/finix/parity.nix` restates facts as prose + fresh code.
Its header lists five NixOS sources it claims to mirror. Auditing those five
plus the option stubs in `finix/default.nix` found **eleven** divergences.

## Findings

### 1. No packet filter on the desktop — SECURITY

- Declared: `modules/core/networking/firewall.nix` (`enable = true`, TCP 22 /
  22000, UDP 22000 / 21027) and `hosts/y0usaf-desktop/host.nix:102`
  (`allowedTCPPorts = [25565]`).
- `networking` is not whitelisted, so both are deleted.
- `parity.nix` never mirrored the firewall — it is not in its source list.
- `finix/default.nix:139` imports the finix `nftables` module into
  `serverPersistent` **only**. The desktop system never receives it.
- Live: `nft`, `iptables`, `ip6tables` all ABSENT from the system.

This is a regression, not a missing feature. Under NixOS (before 2026-07-17)
`networking.firewall.enable = true` generated and loaded kernel rules at boot.
Since the finix switch nothing has. A missing firewall cannot raise an error,
so the change was invisible.

Listening on all interfaces at audit time: 2222 (sshd), 6006 (tensorboard),
11470 / 12470, 27036 (steam). LAN exposure, not internet exposure — the machine
is behind NAT.

### 2. pipewire has no realtime priority — and the two ledgers disagree

- `hosts/y0usaf-desktop/finix/audio.nix:5-7` — "RT priority (Nice -20 /
  SCHED_RR 99 on NixOS) is NOT ported yet".
- `hosts/y0usaf-desktop/finix/parity.nix:55-58` — "rtkit restores the RT
  scheduling the NixOS pipewire unit got via systemd".
- Live: `rtkit-daemon` runs, but pipewire is `NI=0 CLS=TS RTPRIO=-`. Plain
  timeshare scheduling.

`audio.nix` is correct; `parity.nix` is wrong. Two files in the same directory
assert opposite things about the same fact. Practical effect: xruns under load.

### 3. `auto-optimise-store` inverted

- `modules/core/system/nix-package-management.nix` declares `true`.
- `nix` is not whitelisted. The finix nix-daemon block
  (`persistent.nix:273`) never restates it.
- Live `/etc/nix/nix.conf`: `auto-optimise-store = false`.

Store deduplication is off on a machine whose config says it is on.

### 4. v4l2loopback guard lost

`modules/desktop/apps/obs.nix:12` gates the module on
`config.user.programs.obs.enable`. `parity.nix:133` sets
`boot.extraModulePackages` unconditionally. The kernel module is built and
loaded whether or not OBS is enabled.

### 5. bluetooth guard lost

`modules/core/hardware/bluetooth.nix:7` gates on
`config.hardware.bluetooth.enable`. `parity.nix:29` sets
`services.bluetooth.enable = true` unconditionally.

### 6. bluez dbus packages never restated

`modules/core/hardware/bluetooth.nix` sets `services.dbus.packages =
[pkgs.bluez]`. Dropped by the whitelist, absent from `parity.nix`. Currently
relies on finix's upstream bluetooth module shipping the activation itself —
unverified.

### 7. gamemode username hardcoded

- NixOS `modules/gaming/core.nix:11`: `users.users."${config.user.name}"`
- finix `parity.nix:156`: `users.users.y0usaf` (string literal)

`config.user.name` is an option with a default. These can diverge.

### 8. zram swap priority differs

`zramSwap` in NixOS uses priority 5 by default. `parity.nix:104` uses
`swapon -p 100`. The comment (`parity.nix:148`) calls it a "literal port of
what the NixOS option does at runtime" — it is not literal. Possibly
intentional, but undocumented as a difference.

### 9. uinput attribution stale

`parity.nix:64` credits uinput to asryx autofill. `modules/desktop/apps/bolo.nix`
also needs uinput for dotool, and `bolo.autofill` was enabled 2026-07-29. The
ledger names one consumer of two.

### 10. Option stub default contradicts the host — LATENT

`finix/default.nix:105` declares stub options so guards in kept config can
evaluate:

    hardware.amdgpu.enable = mkOption { type = bool; default = true; };

`hosts/y0usaf-desktop/host.nix:75` sets `amdgpu.enable = false`. `hardware` is
not whitelisted, so the host's `false` is deleted before it reaches the stub.
The finix system evaluates `hardware.amdgpu.enable == true`.

Currently harmless: `modules/core/hardware/amd.nix:34` gates only
`services.xserver.videoDrivers` and `nixpkgs.config.hipSupport`, both dropped
anyway. It becomes live the moment anything whitelisted (a package, a manzil
file) is added under that guard.

### 11. `trusted-users` has a duplicate

Live `nix.conf`: `trusted-users = root root y0usaf`. Cosmetic.

### Not drift

`systemd.services.tailscale-resume` (restart tailscaled after suspend) has no
finix equivalent, but `hosts/y0usaf-desktop/finix/graphical.nix:33` documents
"desktop never suspends. Revisit with phase 2b if suspend ever matters." That
is a decision, not an oversight.

## Scale of the seam

Declarations in `modules/` by top-level key, whitelist status:

    KEPT      user 19, manzil 92, environment 88, fonts 2          = 201
    DROPPED   systemd 19, services 20, users 11, boot 10,
              hardware 9, programs 7, networking 6, nix 4,
              xdg 4, virtualisation 3, security 2                  =  95

25+ modules set both kept and dropped keys — half the file is live, half is
inert, on adjacent lines. 29 modules carry hand-written comments about the
shim, because the code has nowhere to record which universe a line belongs to.

## Conclusion

One mirror is derived from its source and has no drift in ~250 entries. One
mirror is hand-copied and has eleven divergences across five facts. Same repo,
same author, same month.

The variable is not care. It is whether a human is responsible for keeping two
files in agreement.

## Facts rescued from NixOS-only modules deleted 2026-08

These modules were inert under the compat-import whitelist (they evaluated and did nothing) and were removed with the desktop/server closure hashes proven unchanged.

- `modules/core/boot/loader.nix` — Limine enabled, max generations 5, secure boot enabled; EFI variables writable with `/boot` EFI mount — `ported: hosts/y0usaf-desktop/finix/boot.nix:84-102` (Limine and writable EFI are ported; the current desktop intentionally uses maxGenerations 20 and firmware Secure Boot remains off, as documented in `finix/NOTES.md:1197`).
- `modules/core/boot/kernel.nix` — latest Linux packages, `kernel.unprivileged_userns_clone=1`, AMD GPU kernel parameters under `hardware.amdgpu.enable` — `ported: hosts/y0usaf-desktop/finix/persistent.nix:145-146,174-185; hosts/y0usaf-desktop/finix/graphical.nix:45-53` (the desktop's active GPU is NVIDIA; its AMD-related boot choice is explicit in persistent.nix).
- `modules/core/networking/networkmanager.nix` — NetworkManager enabled — `UNPORTED` (intentional: wired `dhcpcd` covers this desktop, documented in `hosts/y0usaf-desktop/finix/persistent.nix:13-16` and `finix/NOTES.md:309-314`).
- `modules/core/networking/firewall.nix` — firewall enabled, TCP 22/22000, UDP 22000/21027 — `ported: hosts/y0usaf-desktop/finix/firewall.nix:62-84; hosts/y0usaf-server/finix/services.nix:112-140` (ports are deliberately replaced/scoped; see desktop firewall rationale at lines 21-38).
- `modules/core/security/polkit.nix` — polkit enabled — `ported: hosts/y0usaf-desktop/finix/parity.nix:23,39-42`.
- `modules/core/security/rtkit.nix` — rtkit enabled — `ported: hosts/y0usaf-desktop/finix/parity.nix:23,43`.
- `modules/core/system/nix-ld.nix` — nix-ld enabled with `stdenv.cc.cc.lib` and zlib — `UNPORTED` (real gap; no nix-ld declaration was found in either native host tree).
- `modules/core/system/substituters.nix` — XDG nix dirs, connect-timeout 5, fallback, one download attempt, LAN/tailnet/Cachix substituters and keys — `ported: hosts/y0usaf-desktop/finix/persistent.nix:273-294` (the native block carries the active LAN/tailnet cache and timeout/fallback policy).
- `modules/core/system/nix-cache.nix` and `nix-package-management.nix` — Nix settings including `auto-optimise-store = true`, trusted-users, max-jobs — `ported: hosts/y0usaf-desktop/finix/persistent.nix:273-294` for trusted users/settings; `UNPORTED` for `auto-optimise-store` and `max-jobs` (real gap, also recorded by the existing audit at `finix/DRIFT-AUDIT.md:95-99` for auto-optimise-store).
- `modules/core/virtualization/vm.nix` — optional libvirtd/QEMU, swtpm, OVMF, non-root, virt-manager — `UNPORTED` (intentional optional feature; no VM enablement exists in either native host tree).
- `modules/core/virtualization/android.nix` — optional Waydroid plus ashmem_linux/binder_linux kernel modules — `UNPORTED` (intentional optional feature; no Waydroid enablement exists in either native host tree).
- `modules/core/hardware/i2c.nix` — `hardware.i2c.enable = true` — `ported: hosts/y0usaf-desktop/finix/parity.nix:51-53`.
- `modules/core/services/forgejo.nix` — Forgejo PostgreSQL/LFS, ports/domain/SSH settings, pinned uid/gid, PostgreSQL enablement — `ported: hosts/y0usaf-server/finix/services.nix:103-147,166-200,275-314` (native service/state and pinned uid/gid are present; native firewall ports are at `services.nix:132-133`).
- `modules/core/services/mediamtx.nix` — WebRTC port 4200, public-IP environment updater, firewall TCP/UDP 4200 — `ported: hosts/y0usaf-server/finix/services.nix:132-133,258-270,316-338`.
- `modules/core/services/n8n.nix` — n8n Node.js path, `N8N_SECURE_COOKIE=false` — `UNPORTED` (intentional temporary decision: the native service comments that n8n was dropped because nixpkgs 2.31.4 is unbuildable, `hosts/y0usaf-server/finix/services.nix:251-256`; the decision is also recorded in `finix/NOTES.md:977-978`).
- `modules/core/services/nginx.nix` — recommended proxy settings — `ported: hosts/y0usaf-server/finix/services.nix:361-406` (native nginx reverse proxy includes the required proxy/websocket/timeout settings).
- `modules/core/services/openssh.nix` — key-only sshd on port 2222, tailnet firewall allowance, authorized keys, known-host pins — `ported: hosts/y0usaf-server/finix/services.nix:103-110,129-133,158-164; hosts/y0usaf-desktop/finix/firewall.nix:72-80` (native ports are intentionally host-specific: server sshd 2200, desktop 2222).
- `modules/core/services/syncthing-proxy.nix` — nginx reverse proxy to Syncthing GUI 8384 — `ported: hosts/y0usaf-server/finix/services.nix:361-403`.
- `modules/core/services/tailscale/config.nix` — Tailscale SSH/open-firewall flags, resume restart unit — `ported: hosts/y0usaf-desktop/finix/parity.nix:60-93; hosts/y0usaf-server/finix/services.nix:225-249` (the desktop native path asserts SSH; the server has the persistent rescue task).
- `modules/core/services/tailscale/hosts.nix` — tailnet host aliases for Syncthing and Forgejo — `ported: hosts/y0usaf-server/finix/services.nix:160-164`.
- `modules/core/services/scx.nix` — scx_lavd scheduler with rustscheds package — `UNPORTED` (real gap; no scx declaration was found in either native host tree).
- `modules/core/services/dbus.nix` — dbus enabled with dconf and gcr packages — `ported: hosts/y0usaf-desktop/finix/graphical.nix:64-69` (dbus is enabled natively; dconf/gcr are not separately declared in the host trees).
- `modules/core/services/btrbk.nix` — daily snapshots, `timestamp_format = long`, preserve minimum 2d and 7d/4w, `/btrfs` snapshot directory `_snapshots`, subvolumes `@dcim` and `@music` — `ported: hosts/y0usaf-server/finix/services.nix:202-218`.
- `modules/desktop/session/system/gvfs.nix` — gvfs enabled — `ported: hosts/y0usaf-desktop/finix/materialized-packages.nix:24-25` (native package bridge supplies gvfs; no separate service toggle).
- `modules/desktop/session/system/upower.nix` — upower enabled — `ported: hosts/y0usaf-desktop/finix/parity.nix:45-49`.
- `modules/desktop/session/system/udisks2.nix` — udisks2 enabled — `ported: hosts/y0usaf-desktop/finix/parity.nix:23,45-49`.
- `hosts/y0usaf-desktop/user.nix` — persisted password hash files for desktop user and root — `ported: hosts/y0usaf-desktop/finix/persistent.nix:298-308`.
