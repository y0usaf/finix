# Finix migration — session notes (2026-07-14, ~01:45)

## STATUS: bare-metal trial FULLY WORKING ✓

Finix boots on y0usaf-server via kexec, runs sshd/dhcpcd/getty, and every
guard + return path is validated. The server is back on NixOS right now.

## What works (all verified on metal tonight)

- `nix run .#finix-server-trial` → kexec jump → Finix up in ~30s at
  192.168.2.66, ssh key auth works (`ssh y0usaf@192.168.2.66`; login shell
  has no PATH — `export PATH=/run/wrappers/bin:/run/current-system/sw/bin`)
- guard: HW watchdog armed across the jump (KExecWatchdogSec=2min), petted
  by finix `watchdog-keepalive`
- auto-return to NixOS after 10 min — validated 3×
- keep marker: `sudo touch /persist/finix-trial/keep` (needs sudo, dir is
  root-owned) → box stays past window — validated
- manual return: `sudo initctl reboot` → NixOS — validated
- /nix rw-mounted, /nix/store ro-bind (store protected)
- /persist mounted via fstab (needs neededForBoot, see gotchas)
- kmsg flight recorder → /persist/finix-trial/kmsg-*.log (92KB/boot)
- boot breadcrumbs → /persist/finix-trial/boot-*.log (mounts, initctl
  status, dmesg, ip)
- no more stray watchdog resets after return (single-watchdog fix)

## Root causes found tonight (chronological pain order)

1. **"instant death at 13.5s" for ~10 trials = auto-return's bare `sleep`**:
   finit spawns processes with NO usable PATH; `sleep 600` failed instantly
   and fell through to `exec initctl reboot`. The box was never crashing —
   it was obeying a broken timer. EVERY script now sets explicit PATH
   (`lib.makeBinPath`) and auto-return fails safe (`|| exit 1`).
2. **ssh "Permission denied" on metal**: UsePAM/StrictModes were disabled
   "VM-only" in server-vm.nix, but the trial root is tmpfs too → PAM
   rejected the account (no persistent shadow). Moved to common.nix.
3. **Stray reset ~2min after each return**: two watchdog drivers
   (intel_oc_wdt + iTCO_wdt) → watchdog0/1 ordering nondeterministic; the
   keepalive's open() armed the spare, reboot left it armed unpetted.
   Fixed: intel_oc_wdt ONLY, both sides (NixOS guard blacklists iTCO_wdt;
   trial modprobe.d blacklist too).
4. **`ro` option on /nix**: btrfs ro/rw is a superblock property of the
   first mount → made the whole fs unmountable-rw (/persist). Removed;
   store protected by finix's remount-nix-store ro bind instead.
5. **Recorder never wrote**: finit reaps a run task's cgroup on exit →
   backgrounded subshell killed. Now a supervised `finit.services` entry
   with `commit=1` mount, no sync loop.

## Upstream finix bugs/gaps to report

- `modules/finit/mount.nix` only generates mount tasks for `neededForBoot`
  filesystems — everything else is written to /etc/fstab and **never
  mounted**. Workaround: neededForBoot=true on /persist.
- dhcpcd module: forking + pidfile tracking never latches (tracked pid 0,
  restart loop). Workaround in common.nix: run foreground `-B` (mkForce).
- No default PATH for finit-spawned processes and for the initrd's
  standalone `sh` (bit us repeatedly; also affects interactive ssh login
  shells — worth checking finix's profile/env setup for a proper fix).

## Hard-won debugging infrastructure (keep!)

- **Beacon initrd** (`beaconInit`/`beaconInitrd` in finix/default.nix):
  wraps /init with pre-finit netconsole + kmsg markers. The ONLY reliable
  netconsole on this box (finit-task netconsole races NIC bring-up; NIC
  reset at coldplug kills the stream anyway).
- Desktop listener: `nc -ulk 6666 > /tmp/netconsole.log` (+ firewall rule
  for UDP 6666 on desktop; was inserted at runtime, NOT persisted —
  re-add if needed). Beacon targets 192.168.2.28 / MAC 58:11:22:b7:f0:29.
- kexec selftest pattern (kexec same-NixOS with marker cmdline) proved the
  hardware kexec path early.
- No EFI pstore after kexec on this box — don't rely on it.

## Layout

- `finix/default.nix` — mkFinixSystem, VM + trial packages, beacon initrd,
  trial driver script (guard checks live in the here-doc)
- `finix/common.nix` — shared base (ssh, user, dhcpcd fix, sudo)
- `finix/server-vm.nix` — phase-1 QEMU VM (`nix run .#finix-server-vm`... 
  actually `nix build .#finix-server-vm && ./result/bin/run-finix-server-vm`,
  ssh -p 22222)
- `finix/server-trial.nix` — bare-metal trial (guards, recorder,
  breadcrumbs, auto-return, net-fallback)
- `hosts/y0usaf-server/finix-guard.nix` — NixOS side (watchdog arming,
  kexec-tools); deployed and active

## Server facts

- disk: /dev/sda2 btrfs UUID 9dfc38c4-5c75-471d-9106-80ff9175ab92,
  subvols @nix @persist @home @music @dcim @pictures @jellyfin ...
- NixOS kernel 7.1.3 == trial kernel (pinned linuxPackages_latest; the
  match was needed during debugging, probably relaxable now)
- NIC eth0 (r8169), DHCP gives .66 (also the static fallback)
- watchdog: intel_oc_wdt (iTCO blacklisted both sides)
- `server` ssh alias = y0usaf-server hostname (only resolves under NixOS);
  finix trial = y0usaf@192.168.2.66

## Next steps (phase 3)

1. Service parity on trial: docker/podman, jellyfin, forgejo, syncthing,
   caddy... (inventory NixOS server services first: `nixos/hosts/y0usaf-server/`)
2. Persistence design: /persist secrets for user password hash + ssh host
   keys (currently regenerated each boot → host key churn at .66)
3. Longer trial windows (bump `trialSeconds`) as confidence grows
4. Eventually: install finix bootloader entry properly (end the kexec era)
   — only after service parity
5. Revisit UsePAM=false / StrictModes=false for a persistent-root system
6. File the upstream issues (mount.nix, dhcpcd, PATH)
