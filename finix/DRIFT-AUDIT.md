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
