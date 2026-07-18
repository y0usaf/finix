# Finix migration — session notes (updated 2026-07-16: desktop phase 1 staged; server PROMOTED 2026-07-15)

## DESKTOP (y0usaf-desktop) — phase 1 staged 2026-07-16, NOT yet booted

Same dual-boot architecture as the server: NixOS keeps /boot/limine and the
BootOrder head; finix lives in the self-contained \EFI\finix island and
boots one-shot at a time until it earns promote. Windows entry untouched.
Secure Boot is DISABLED in firmware (sbctl keys exist but aren't enforced) —
unsigned island Limine boots; if SB is ever enabled, sign the island first.

Phase 1 scope (console skeleton, `finix/hosts/y0usaf-desktop/persistent.nix`):

- tmpfs root (4G) + @nix/@persist/@home/@btrfs/ESP + data subvols
  (@steam/@pictures/@dcim/@music/@home-old ro) — fstab parity with NixOS
- impermanence REPLAYED, single source of truth:
  hosts/y0usaf-desktop/impermanence.nix is a pure-literal function; the
  finix host imports it and replays the same allowlist (system /var dirs as
  neededForBoot fstab binds; the 250-entry user allowlist + files as ONE
  `persist-user-binds` finit task; /etc/* entries excluded — /etc is
  finix-managed: machine-id copied by activation, ssh host keys consumed in
  place from /persist/etc/ssh, exactly the server pattern). KEEP
  impermanence.nix pure literals or the finix eval breaks.
- sshd: NixOS ed25519 host key, authorized-keys copy activation,
  UsePAM+StrictModes on; passwordFile from /persist/secrets (y0usaf + root)
- dhcpcd (eno1/igc) + static fallback 192.168.2.28; nix-daemon; getty
  tty1/tty2; kmsg recorder + breadcrumbs via new shared
  finix/modules/diagnostics.nix (server still runs its inline copy —
  migrate it there on its next planned deploy)
- kernel: linuxPackages_latest, amd_pstate=active mitigations=off,
  zenpower via extraModulePackages, panic=30/oops=panic fall-home params
- boot driver: `nix run .#finix-desktop-boot -- local install|oneshot|...`
  (mkIsland generalization; desktop drives its OWN ESP under sudo, AMD
  amd-ucode.img prepended instead of intel); config deploys:
  `nix run .#finix-desktop-deploy -- local test|switch` — REFUSES to run
  under systemd/NixOS (activation would clobber the live /etc); first
  activation happens via the island boot, not a NixOS-side switch

Deliberately deferred (phase 2+): NVIDIA + graphical session
(seatd/dbus/niri/pipewire), user services, zram (no upstream module), /swap
subvol (unused under NixOS too), NetworkManager/bluetooth/docker/tailscale,
@home-blank rollback in the finix initrd (NixOS still rolls @home back on
ITS boots; allowlisted writes land in /persist either way — same durability,
deferred @home-noise cleanup). Steam validation gates promote.

New upstream gotcha found: modules/lib/utils.nix escapePath maps BOTH "/"
and "/root" to stanza name "root" → neededForBoot collision assert. /root
is therefore bound by the persist-user-binds task, not fstab.

Verification status: system + drivers build; server closure verified
byte-identical after the mkIsland/mkDeploy refactor (topLevel still
7jhzs63m…); NixOS desktop drv unchanged. NOT yet booted on metal.

Desktop next steps: `finix-desktop-boot local install` (opens test window,
BootOrder stays NixOS-first) → console oneshot → verify binds/sshd/nix-
daemon/logs → iterate phase 2 (session stack) → steam → promote only after
the graphical stack is boring.

2026-07-18 first boots + FLICKER ROOT CAUSE: boot 1 (07-17 00:50Z) had no
firmware in image → amdgpu psp/dcn/gc failed AND nouveau GSP ctor failed
-2 → stable efifb console. Fix added linux-firmware for amdgpu — side
effect: nouveau got its GSP blobs, took the dGPU (monitor is on DP-4 of
the NVIDIA card; iGPU has NO cable), kicked simpledrm, and cannot hold
the G9-class 3840x1080 super-ultrawide link (`gsp ctrl cmd:0x00731341
failed` + `DP-4: invalid native reply 0x03` bursts; DRM state reads
stable while the panel strobes — silent GSP link cycling, likely
DSC/high-refresh). No live mitigation exists: single monitor on dGPU,
rmmod = dark screen, fb0 exposes one mode. FIX: modprobe.d `blacklist
nouveau` (server iTCO pattern) → dGPU-connected console stays on
simpledrm (boot-1 proven); marker desktop-phase1.2, slot 2h5yv11z staged
as island default 2026-07-18 from INSIDE the flickering boot.

Phase-1 verification PASSED (run live in the phase1.1 boot, flicker and
all): tmpfs root 4G, 268 persist binds mounted, /nix /persist /home
/boot + data subvols ok, sshd up (host key from /persist), nix-daemon
up, uid y0usaf=1001 correct, diagnostics logs landing in
/persist/finix-boot/. Gotchas found: nix.conf lacks
`experimental-features nix-command flakes` (flag-workaround; bake into
services.nix-daemon settings in phase 2); getty shows 0 agetty procs
post-login (login shell replaces it — fine).

2026-07-18 PHASE 2a staged (slot pambvcx8, marker desktop-phase2.0, NOT
yet booted): new hosts/y0usaf-desktop/graphical.nix — NVIDIA proprietary
via upstream `hardware.nvidia` (closed, mkDriver 595.80 pinned = same drv
as NixOS, modesetting on, gsp OFF mirroring NixOS, PM off — upstream PM
path wants programs.zzz sleep backend, desktop never suspends), NixOS
kernelParams parity (PAT/ResizableBar/AggressiveVblank/vrr_memclk/
TemporaryFilePath), hardware.graphics + enable32Bit (Steam gate), eudev
INSTEAD of mdevd on this host (mkForce off; nvidia udev rules + phase-2b
libinput need libudev; server keeps mdevd), seatd + dbus groundwork,
y0usaf += video/render/seat. allowUnfree += nvidia-x11 +
nvidia-kernel-modules.

UPSTREAM GAP found: finix nvidia module sets extraModulePackages =
package.bin — stale vs nixpkgs' kernel-module split; .bin has no
lib/modules so nvidia.ko silently never lands in the aggregate. Fixed
host-side: boot.extraModulePackages = [package.mod]. Add to the upstream
issue list.

Phase-2a BOOTED GREEN (2026-07-18, slot pambvcx8): all four nvidia
modules loaded, /dev/nvidia* + /dev/dri/card1,2 + renderD128,129 present,
console readable on the nvidia fbdev, eudev coldplug clean (eno1 name
kept, by-uuid links, all mounts), dbus up. Benign: driver probes
gsp_ga10x.bin and logs -2 (gsp.enable=false ships no GSP fw — same as
NixOS). seatd was NOT running → see 2b.

Phase-2b DEPLOYED LIVE same boot (slot s1qhrpb1 staged, marker
desktop-phase2.1) — first use of finix-desktop-deploy on this host
(config-only path, no reboot): new hosts/y0usaf-desktop/session.nix.
- seatd root cause: upstream module defaults runlevels [34]; finix boots
  runlevel 2 → service never eligible, initctl shows misleading "halted
  exit 0". Fix: runlevels mkForce "234" (mkForce needed — upstream sets
  a bare default). Its `-n %n` notify:s6 command is FINE (udevd uses the
  same pattern). UPSTREAM GAP.
- XDG_RUNTIME_DIR without logind: finit task creates /run/user/1001
  (0700 y0usaf) + profile.d export + shim fallback. Replace with
  elogind + pam_elogind when portals land (2c) — finix pam has NO
  elogind hooks today (checked).
- tomoe-session shim replicated from the NixOS module (env scoped to
  compositor; cursor/font from flakeInputs.cursors/fonts directly —
  packages cross the universe split, only modules don't). No
  TOMOE_PORTAL_CHOOSER yet (portals are 2c). No GBM_BACKEND/EGL vendor
  forcing (smithay renderer probe breaks, same as NixOS shim).
- fonts via upstream fonts.fontconfig + fonts.packages (Departure Mono
  UC + Noto CJK + emoji); foot family comes from persisted ~/.config.
- packages: tomoe, foot, grim/slurp/wl-clipboard-rs/jq/swaybg/
  xwayland-satellite, nushell (config.nu on persisted /home; login shell
  stays bash for rescue), fzf/rg/fd.
- nix-daemon settings.experimental-features = nix-command flakes baked
  (phase-2a papercut).
Verified live: seatd running + /run/seatd.sock (root:seat), y0usaf in
video/render/seat, /run/user/1001 ok, tomoe-session/nu/foot on PATH,
fc-list resolves Departure. tomoe FIRST LIGHT not yet attempted — needs
a fresh login on tty2 (groups + profile) and the compositor grabs the VT.

Phase-2c backlog: pipewire (NO upstream module — hand-roll finit
service; no audio until then), elogind+pam for portals + session dbus,
xdg-desktop-portal-gtk + TOMOE_PORTAL_CHOOSER, Steam (32-bit GL already
staged), decide login shell nushell, decide seatd vs logind libseat
backend long-term.

2026-07-18 PHASE 2b+ tomoe FIRST LIGHT confirmed by user (session runs,
apps launch). Then:

2026-07-18 packages-bridge (marker 2.2, slot k544ilnw): new
packages-bridge.nix EVALS the NixOS system for this host and reuses its
environment.systemPackages list wholesale — modules can't cross the
universe split, evaluated DERIVATIONS can. One source of truth, ~1830
binaries, zero double bookkeeping. denyList: networkmanager, docker,
docker-compose. Costs accepted: finix eval also evals NixOS (~s + RAM);
bridged drvs come from the NixOS pkgs instance (cudaSupport=true,
NixOS unfree allowlist — finix's predicate never re-evals them).
Corrected en route: "ln" is NOT the browser (librewolf is; Mod+2 bind
now spawns librewolf); coreutils ln wins the sw/bin collision, harmless.

2026-07-18 PHASE 2c audio + portals + user services DEPLOYED LIVE
(marker 2.3, slot abqp03vx staged — first install attempt was aborted
mid-run and re-run; VERIFY `current=` on the ESP after every install):
- audio.nix: pipewire/wireplumber/pipewire-pulse as finit services
  (user y0usaf + environment attrs — server syncthing pattern), wait
  wrappers for /run/user/1001 + pipewire-0 socket ordering, RNNoise
  filter-chain ported verbatim (toJSON is valid SPA-JSON), LADSPA_PATH
  env, y0usaf += audio group (no logind ACLs → /dev/snd via group).
  VERIFIED: Scarlett 2i2 default sink/source, rnnoise_source node up,
  cmus plays. NOT ported: RT priority (NixOS Nice -20/SCHED_RR 99) —
  needs rtkit (dbus+polkit) or finit rlimit work; benign pw_rtkit
  session-bus error in wpctl output is this gap.
- session.nix: shim now exec's dbus-run-session (session bus for
  compositor + children; portals dbus-activate there), XDG_DATA_DIRS →
  sw/share for dbus-1 services + .desktop discovery, TOMOE_PORTAL_CHOOSER
  restored (verbatim foot+fzf chooser port), packages +=
  xdg-desktop-portal{,-gtk} (tomoe's own portal ships in its package).
  Portals need a session STARTED under the new shim — relog tomoe once.
- syncthing: desktop instance, server pattern, GUI 127.0.0.1:8384.
- ssh user-service: nothing to port — pure dotfiles, already persisted.
Still open after 2c: RT audio, elogind-vs-manual XDG_RUNTIME_DIR
(portals fine on dbus-run-session for now), Steam validation (gates
promote), nushell as login shell decision, bluetooth (blueman/bluez
services not ported), OBS virtual cam (v4l2loopback module), power-cut
drill, then PROMOTE.

2026-07-18 PHASE 2d PARITY SWEEP deployed live + staged (marker 2.4,
slot 4a8afirz, verified current= on ESP): new parity.nix +
bridge/session extensions, user is promote-ready comfort-wise, this
closes the functional gap list.
- upstream modules ENABLED (NOT in mkFinixSystem baseline — imported
  via flakeInputs.finix.nixosModules in parity.nix): bluetooth (bluez,
  ControllerMode dual + FastConnectable + AutoEnable ≈ powerOnBoot),
  polkit (adminIdentities y0usaf), rtkit.
- tailscaled + tailscale-ssh assert ported verbatim from the server;
  state was ALREADY persisted via the impermanence replay → desktop
  kept its tailnet identity (100.90.54.18, `ssh rescue` path intact).
- zram-swap finit task (50% RAM zstd, prio 100) — hand-rolled, no
  upstream module; VERIFIED /dev/zram0 46.8G active.
- v4l2loopback (exclusive_caps=1) for OBS virtual cam; tun for
  tailscale; both in boot.kernelModules + extraModulePackages.
- udev-rules BRIDGE: NixOS services.udev.packages reused, each package
  SANITIZED (sed /systemd/d per .rules file; find -type f — some rule
  "packages" are single files, some dirs) — eudev's validator hard-fails
  on /run/current-system/systemd/bin/systemd-run references (lvm2 +
  extra-udev-rules were the culprits). Keeps steam-devices, ntsync,
  DualSense/vial hidraw perms, i2c.
- gamemode group + membership (gamemoded dbus-activates per session).
- session shim: __GL_*/CUDA_*/NVIDIA_DRIVER_CAPABILITIES sessionVar
  parity; polkit agent (pkgs.polkit_gnome — the NixOS module's "lnAgent"
  name is cosmetic) spawns INSIDE dbus-run-session via a
  tomoe-session-inner wrapper so it shares the session bus.
- xwayland-satellite: NO port needed — tomoe's init.lua process.once
  starts it from a store path; confirmed running.
VERIFIED live: bluetoothd/polkitd/rtkit-daemon/tailscaled running,
tailscale-ssh + zram done, steam/i2c rules in /etc/udev/rules.d.
OPEN (minor): pipewire threads still SCHED_OTHER after rtkit restart —
module-rt↔rtkit handshake needs a look (audio works regardless); RELOG
required for: session bus → portals + polkit agent + gamemoded +
TOMOE_PORTAL_CHOOSER. Then Steam run = the promote gate; power-cut
drill; promote via `nix run .#finix-desktop-boot -- local promote`
(refuses unless BootCurrent IS the island — do it from a finix boot).

## SERVER STATUS

Phases 1–3 are complete: VM → guarded bare-metal trial → full service
parity, all verified on metal. The 24h soak was accepted. Stage 2 is now
booted: the persistent Finix system is running at 192.168.2.66 via guarded
kexec, with persistent `/var/log`, hostname takeover, writable `/nix/store`,
`nix-daemon`, watchdog keepalive, and all services healthy.

The first persistent boot exposed SSH ownership/PAM problems; two recovery
cycles were needed. The fix copies generated authorized keys to `/persist`
so the active config now has `UsePAM=true` + `StrictModes=true`. The SSH
deploy path works without kexec (activation marker deployed and verified).

Stage-3 recon + tooling landed (2026-07-14 late): box is EFI, efibootmgr
works from both OSes, Limine is 12.4.0 (app-adjacent config supported), and
the NixOS Limine installer preserves BootOrder on redeploys. The bootloader
takeover no longer needs a console: `nix run .#finix-server-boot` manages a
self-contained ESP island + one-shot BootNext boots (see "Stage 3
mechanism" below).

First contact happened the same night — see "2026-07-15 incident log"
below: BootNext works, finix survived its FIRST direct firmware boot with
all services green (accidental, via the stale default_entry line), a warm
reboot then hung undiagnosed, the user menu-picked NixOS at the console
(rescue drill, done for real), and a NixOS deploy scrubbed the stale
line: unattended boots now land in NixOS deterministically.

INCIDENT #2 (2026-07-15 ~10:29Z) + ROOT CAUSE + FIX: the official island
boot froze hard after 5.5h (mid-heartbeat, zero kernel output, watchdog
never brought it back); forensics exposed the systemic difference —
direct firmware boots ran the RAW BIOS microcode (0x1a) while every
kexec-era boot silently inherited NixOS's early-loaded 0x21 (microcode
survives kexec, not power cycles). Both direct-boot anomalies (00:19
hang, 10:29Z freeze) ran 0x1a; ADL-N 0x1a→0x21 spans years of stability
erratas matching the freeze signature. Fix live: island installer now
prepends intel-ucode.img to every staged initrd (bridge entry patched in
NixOS config too, deploy pending). Re-oneshot 13:28Z: `microcode: Updated
early from 0x1a` on a direct boot, all services green, deadman cleared.
PROMOTED 2026-07-15 ~13:37Z, user's call (accepted risk, see below): after
an island→island warm reboot test on fixed microcode came back green in
44s (the 00:19 pattern, retired), BootOrder went Finix-first:
0000,0003,0002,0001. The multi-day soak now happens POST-promote — same
runtime, different failure landing: if the freeze recurs, a power cycle
lands back on the island (possibly frozen again) instead of NixOS; the
escape is the console menu (island conf carries a NixOS rescue entry) or
`demote` from a live ssh window. Deadman still guards every island boot
(crash-before-sshd → parks in NixOS).

## DIRECTION — the endgame

Goal: y0usaf-server runs finix as its installed OS; NixOS stays on disk
forever as a bootable rescue entry (it costs nothing). Deploys then target
finix; the NixOS config is frozen except for security fixes.

Stages, each gated on the previous one being boring:

1. **Soak** (DONE): jump + `keep` marker, leave finix up for a day+.
2. **Persistent system** (DONE): `finix/server-persistent.nix`; no
   auto-return, beacon initrd, or netconsole scaffolding; tmpfs-root
   impermanence + binds retained; SSH deploy path exercised.
3. **Bootloader takeover** (DONE 2026-07-15): ESP island + BootNext
   one-shots via `nix run .#finix-server-boot` — no console; risky
   transitions fell home to NixOS automatically. kexec era over; the
   NixOS guard module (watchdog arming) can be retired from the NixOS
   config but the NixOS entry itself stays as rescue.
4. **Steady state**: finix default boot; NixOS entry pinned + GC-rooted;
   guards (watchdog keepalive, panic=…) stay in the persistent config —
   they're cheap and they saved us repeatedly.

Abandon-NixOS checklist (all must be true before `promote` makes the
island the cold-boot default; items after the first five happen DURING
stage 3):
- [x] 24h+ soak with zero service flaps (`initctl status` clean, no
      restarts logged)
- [x] btrbk fired from finix cron ON THE ISLAND BOOT (2026-07-15 01:19 EDT,
      induced: /etc/cron.d one-shot replica of the systab line — same
      store paths/PATH/SHELL — produced @dcim/@music.20260715T0119;
      probe file removed. Note the T0000 snapshots that night were the
      NixOS systemd timer (box was NixOS at midnight) — that validates the
      production-bug fix on the NixOS side too. Tonight's natural
      midnight fire double-confirms the literal /etc/crontab entry.
- [x] dhcpcd renewed a lease without dropping .66 (2026-07-15 01:20 EDT,
      induced: `dhcpcd -N eth0` against the running daemon → REQUEST →
      ACK from 192.168.2.1, same 3-day lease, IP/route kept, SSH session
      uninterrupted; lease renew horizon is 36h so the natural renewal
      was not worth waiting for)
- [ ] a reboot-from-power-cut test (hard reset → NixOS today; after
      stage 3 → finix) comes up green unattended
- [x] direct boots run current microcode (2026-07-15 13:28Z: island boot
      logs `Updated early from 0x1a` → 0x21; was the root cause of both
      direct-boot failures — see incident #2)
- [x] island→island warm reboot on fixed microcode (2026-07-15 13:35Z:
      oneshot from the running island, up in 44s, `Updated early from
      0x1a` present, deadman cleared, services 200 — the 00:19 pattern
      is retired)
- [~] multi-day island soak on FIXED microcode — converted to a
      POST-promote watch by user decision (promote itself changes only
      the failure landing zone, not runtime). Watch for flaps/freezes;
      recurrence → power cycle → console NixOS pick or `demote`, then
      diagnose via /persist/finix-boot/ + syslog heartbeat.
- [x] deploy-to-finix path exercised (config change applied without
      kexec)
- [x] firmware honors BootNext (2026-07-15 ~00:15): `bootnext-test` set
      BootNext=0002 and the firmware booted it (landed in finix via the
      then-live stale default line rather than NixOS — see incident log —
      but the BootNext mechanism itself is PROVEN on this board)
- [x] island one-shot boot GREEN — OFFICIAL (2026-07-15 ~04:55Z): slot
      7jhzs63m (gen WITH deadman + flight recorder) via install + oneshot.
      BootCurrent=0000 (island), up in ~50s, 32 finit jobs running/done,
      forgejo/syncthing 200 via LAN, n8n /healthz 200 on localhost,
      bootnext-deadman armed → cleared, watchdog petted, efibootmgr +
      /boot mount usable, recorder + breadcrumb logs written to
      /persist/finix-boot/, initrd markers present in the kmsg log,
      tailscale up (tailnet :22 answers). Stale April Boot0000 + finix.efi
      deleted by install. Note: firmware reshuffled BootOrder tail to
      0003,0002,0000,0001 after the oneshot (NixOS entries still first —
      fall-home intact).
- [x] tailscale SSH rescue path LIVE (2026-07-14): `RunSSH: true` set on
      the box (persists in shared /var/lib/tailscale state → finix
      inherits); verified tailscaled answers :22 on 100.105.204.116 with
      pubkey/password auth disabled — pure tailnet identity, no
      sshd/PAM/keys (the class that needed two recovery cycles). Baked in:
      NixOS `extraSetFlags ["--ssh"]` (up-flag alone had rotted — RunSSH
      was false), finix `tailscale-ssh` finit task, desktop `ssh rescue` /
      `ssh rescue-root` aliases (own known_hosts; TS host key ≠ sshd's).
      Remaining: tailnet ACL is default `check` mode → complete one
      browser check end-to-end; optionally switch the ssh rule to
      action=accept (or set checkPeriod) in the admin console; re-verify
      under the island boot + after a desktop rebuild (`ssh rescue`).
- [ ] BIOS: AC power loss → power on (turns a smart plug into a remote
      reset button; cheap, optional)
- [x] rescue drill (done EARLY, under real conditions, 2026-07-15 ~00:50):
      hung finix boot → user at console → Ctrl+Alt+Del → Limine menu →
      NixOS generation → clean boot, 0 failed units. The post-promote
      `sudo boot-nixos` variant remains to be drilled once promoted.


## Stage 3 mechanism — ESP island + BootNext (no hands required)

Ownership split (the crux): NixOS keeps /boot/limine + \efi\limine forever
(frozen config; its installer re-reads and preserves BootOrder, and never
prunes \EFI\finix — the April leftovers survived every deploy). Finix gets
a fully self-contained island at \EFI\finix\:

- `BOOTX64.EFI` — own copy of Limine 12.4 (reads app-adjacent limine.conf
  first, so it can never collide with NixOS's /limine/limine.conf)
- `limine.conf` — island config, `default_entry: 1` (numeric; no
  name-matching dependency), current slot + previous slot + a chainload
  entry into the NixOS Limine as console convenience
- `kernels/<slot>/{kernel,initrd,cmdline,system}` — slot = store-hash
  prefix of the persistent topLevel; closure gc-rooted per slot
  (`/nix/var/nix/gcroots/finix-esp-<slot>`)
- `slots` — `current=`/`previous=` state; plus a `Finix` EFI boot entry

Driver: `nix run .#finix-server-boot -- <host> <action>` (remote half runs
as root under either OS and self-mounts efivarfs):

- `status`        EFI vars + island state + rendered conf
- `bootnext-test` zero-risk firmware validation (BootNext → Limine entry;
                  both outcomes land in NixOS)
- `install`       stage slot as island default; gcroot closure; force
                  BootOrder NixOS-first = open test window (an untested
                  slot is never the cold-boot default); delete stale
                  April artifacts (Boot0000 "finix", \EFI\finix\finix.efi)
- `oneshot`       BootNext=Finix + reboot: boots the island exactly once.
                  Panic → panic=30 → reset → BootOrder → NixOS. Pre-OS
                  hang (no panic) → one power cycle → NixOS.
- `promote`       BootOrder Finix-first; refuses unless BootCurrent IS the
                  island (`promote-force` overrides)
- `demote`        manual lever back to NixOS-first
- `rollback`      island default → previous slot

Steady-state guards (baked into server-persistent.nix):

- `bootnext-deadman` finit task: arms BootNext=<Limine> at every finix
  boot start, clears it only after sshd listens continuously for 2 min
  (10-min budget). Persistent failure → at most two crash cycles → box
  parks in NixOS, ssh-reachable. Harmless in the kexec era (NixOS is the
  firmware default anyway).
- `sudo boot-nixos`: deliberate one-shot exit to the rescue OS; BootOrder
  untouched, next plain reboot returns to finix.
- Deploy discipline: kernel/initrd/cmdline changes go install → oneshot →
  promote, so the BootOrder head is always a slot that has booted to
  health on THIS box. Config-only changes keep using the SSH deploy path.
- Post-promote, NixOS reboots return to finix (BootOrder). Staying in
  NixOS across a reboot = `efibootmgr -n <Limine>` before rebooting, or
  `demote`.
- NixOS rescue upkeep: generations remain gc-rooted via the shared
  /nix/var/nix/profiles/system. Never `nix-collect-garbage -d` from finix
  — it would delete old NixOS generations the rescue menu points at.

Residual risk (honest): bitrot/hardware corrupting an already-blessed slot
so early that nothing panics = power cycle + keyboard territory — the same
exposure class NixOS has today. Optional hardening later: sd-boot boot
counting (chainloading Limine on exhausted tries) or beacon-initrd
watchdog arming.

Recon facts, CORRECTED after first contact (see incident log): live
limine.conf carried `default_entry: Finix persistent` at line 1 —
provenance: an earlier `boot.loader.limine.extraConfig` takeover attempt
(staged in git, deployed, then reverted in the worktree only). The
2026-07-14 recon called it "inert" because the box kept booting NixOS —
WRONG: those NixOS boots were manual Limine-menu picks by the user. On
this Limine build the FIRST `default_entry` assignment wins and entry-name
matching works, so every UNATTENDED boot selected "Finix persistent".
Scrubbed 2026-07-15 ~01:00 by a NixOS redeploy; verified: single
`default_entry: 2`, unattended boots → NixOS again. Lesson: never leave a
duplicate-key config where the loser is only "probably" the winner — and
the island conf's single-owner numeric `default_entry: 1` design stands.
BootOrder (unchanged all night): 0003 (UEFI OS = \EFI\BOOT fallback) →
0002 (Limine) → 0000 (stale "finix" UKI from April) → 0001 (EFI shell).

## 2026-07-15 incident log — stage-3 first contact (unplanned but rich)

Timeline (box was NixOS, bootnext-test intended as a NixOS→NixOS no-op):

1. ~00:05 first driver run HUNG desk-side: `server` alias resolves via
   MagicDNS → tailnet IP → our OWN new Tailscale SSH intercepted it →
   check-mode waited on a browser. Box untouched. Fixes: driver now forces
   BatchMode/ConnectTimeout (+NIX_SSHOPTS) and targets the LAN IP
   192.168.2.66. Rule: AUTOMATION → LAN IP; tailnet names = humans/rescue.
2. 00:15 `bootnext-test` via LAN: BootNext=0002 honored by firmware ✓ —
   but Limine's 0002 copy honored stale line-1 (first-wins + name match)
   → booted "Finix persistent" instead of NixOS: the FIRST direct
   firmware boot of finix ever, by accident. Result: GREEN. 27 finit jobs,
   forgejo/n8n/syncthing-nginx all HTTP 200, postgres/sshd/tailscaled up,
   watchdog petted, cold NIC init fine (old gen 0kan5fq…, no deadman).
3. ~00:19 `initctl reboot` (returning to NixOS, expected 0003→NixOS):
   loader again picked Finix persistent (same stale line) and that boot
   HUNG — user found the "welcome to finix" banner, no network, tailnet
   offline. ZERO log lines from that boot in /persist/var/log → it died
   before syslog/binds; cause UNKNOWN (candidates: btrfs mount stall,
   coldplug race, r8169 warm-reboot state). The persistent config has NO
   flight recorder (trial-only feature) — that was a mistake, port it.
   Watchdog gap confirmed: direct boots arm nothing until the keepalive
   runs, so a pre-userspace hang sits forever (known residual risk, now
   observed in the wild once).
4. ~00:50 rescue drill FOR REAL: user at console, Ctrl+Alt+Del → Limine
   menu → NixOS generation → up clean (0 failed units). Headless caveat:
   this needed a human because the stale line owned every automatic path.
5. ~01:00 NixOS redeploy: limine.conf regenerated (stale line GONE,
   verified single `default_entry: 2`), bridge entry refreshed to the new
   finix gen 9f4nz259… (bootnext-deadman, tailscale-ssh task, efibootmgr,
   boot-nixos, /boot mount), BootOrder untouched, tailscale extraSetFlags
   asserted. Brief LAN wobble during switch, recovered; `tailscale ping`
   + Tailscale-SSH host-key answer served as liveness checks meanwhile.

Net result: BootNext PROVEN, direct finix boot PROVEN GREEN once, rescue
drill PASSED, deterministic fall-home RESTORED, one open mystery (warm
reboot hang, 1 occurrence) now gating the official oneshot.

Observations parked for later: NetworkManager is active on the NixOS
server (pre-existing; explains dispatcher units in switch output — audit
eventually); tailnet ACL still `check` mode (one browser check pending
end-to-end).

## 2026-07-15 incident #2 — island freeze at 10:29Z, root cause MICROCODE

Timeline: official island boot (04:55:32Z, slot 7jhzs63m) ran green for
5h33m. Postgres collation warnings heartbeat every ~30s in syslog; last
entry 10:28:41Z, next expected ~10:29:10Z never logged. Instant hard
freeze: no error lines before it, no kernel output after boot noise
(kern.log/kmsg recorder mtime = boot+4s), no shutdown path, and the box
did NOT come back — panic=30/oops=panic/softlockup_panic/hung_task_panic
never fired (nothing to fire on a hard lockup below NMI visibility) and
the armed+petted intel_oc_wdt either didn't fire or the post-watchdog
warm reset hung in POST. Tailnet last-seen ~11:14Z (coarse). Box found
dark 13:14Z, no ARP. Manual power cycle → NixOS via BootOrder (fall-home
worked; BootNext had been consumed at 04:55Z, deadman had cleared it).

Forensics trail:
- /persist/finix-boot/ held exactly one kmsg+breadcrumb pair (04:55Z
  boot) → box never re-booted after the freeze, just sat hung.
- kmsg log ends at 11.7s uptime (quiet box thereafter); grep for
  panic/oops/watchdog/mce = boot-time noise only. Death printed nothing.
- syslog (persistent /var/log) gave the exact freeze window via the
  postgres heartbeat rhythm.
- watchdog0/bootstatus = 0 on the recovery boot (power-on clears
  CARDRESET; inconclusive by design — don't chase it next time).
- Divergence hunt NixOS vs island boot logs: NixOS logs `microcode:
  Updated early from: 0x0000001a` (→0x21); island kmsg logged `x86/CPU:
  Running old microcode`. Smoking gun: kexec preserves CPU microcode
  within a power cycle, so ALL kexec-era trials + the 24h soak ran 0x21
  unknowingly; only direct firmware boots (2 ever, both anomalous) ran
  the BIOS's ancient 0x1a.

Fix (live): espIslandScript do_install now stages
`cat intel-ucode.img $system/initrd` per slot (uncompressed early-ucode
cpio first — 070701 magic verified on ESP, 13.7→28.8MB);
hosts/y0usaf-server/finix-boot.nix bridge entry gained
`module_path: …/ucode.img` before the initrd (NixOS deploy pending).
nixpkgs attr is `microcode-intel` (renamed from `microcodeIntel`).
Re-install refreshed slot 7jhzs63m in place; oneshot 13:28Z: direct boot
shows `Updated early from 0x1a`, 18 jobs running, forgejo/n8n 200,
deadman armed→cleared, BootOrder untouched NixOS-first.

Residual honesty: microcode is the best-fit theory (mechanism, timing,
and 2/2 correlation) but hard freezes don't leave receipts — hence the
multi-day soak gate before promote instead of declaring victory.

Noted in passing (non-blocking):
- i915 WARN at intel_bios.c:2793 (VBT vswing) fires on NixOS boots too —
  pre-existing kernel/VBT noise on both OSes, not a differentiator.
- postgres logs collation mismatch (databases created with glibc 2.40,
  running 2.42): housekeeping = `ALTER DATABASE … REFRESH COLLATION
  VERSION` for forgejo + postgres DBs (harmless warning meanwhile; it
  was also our accidental freeze-timestamp heartbeat).

## What works (phase-2 trial infrastructure, verified on metal)

- `nix run .#finix-server-trial` → kexec jump → Finix up in ~30s at
  192.168.2.66, ssh key auth works (`ssh y0usaf@192.168.2.66`; login shell
  has no PATH — `export PATH=/run/wrappers/bin:/run/current-system/sw/bin`)
- guard: HW watchdog armed across the jump (KExecWatchdogSec=2min), petted
  by finix `watchdog-keepalive`
- auto-return to NixOS after the trial window (now 30 min; the 10-min
  version was validated 3×)
- keep marker: `sudo touch /persist/finix-trial/keep` (needs sudo, dir is
  root-owned) → box stays past window — validated
- manual return: `sudo initctl reboot` → NixOS — validated
- /nix rw-mounted, /nix/store ro-bind (store protected)
- /persist mounted via fstab (needs neededForBoot, see gotchas)
- kmsg flight recorder → /persist/finix-trial/kmsg-*.log (92KB/boot)
- boot breadcrumbs → /persist/finix-trial/boot-*.log (mounts, initctl
  status, dmesg, ip)
- no more stray watchdog resets after return (single-watchdog fix)

## Root causes found in phase 2 (chronological pain order)

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

## Phase 3: service parity — VERIFIED ON METAL ✓ (2026-07-14 afternoon)

Ported in `finix/server-services.nix` (trial-only import; VM stays lean).
Versions match NixOS exactly (same nixpkgs pin), so shared state is safe:
forgejo-lts 15.0.3, postgres 16.14, syncthing 2.1.0, n8n 2.27.4,
mediamtx 1.18.2, tailscale 1.98.8.

- postgresql 16 (finix upstream module; pinned to on-disk cluster major;
  initdb skipped via existing PG_VERSION)
- forgejo: reuses /persist/var/lib/forgejo verbatim — app.ini + secret
  files were generated there by the NixOS module; same FORGEJO__*__FILE
  envs as systemd; uid/gid 993/989 pinned both sides; start wrapper waits
  on pg_isready
- n8n: boot task chowns the DynamicUser-owned state to a static n8n user
  (+ /var/lib/private 700→711); systemd re-adopts on return
- syncthing: runs as y0usaf against ~/.config/syncthing on @home (same
  device ID/folders); nginx reverse proxy vhost syncthing-server:80→8384
- tailscaled: state bind from /persist, tun module, CLI in systemPackages
- btrbk: daily via finix cron + providers.scheduler, /btrfs subvolid=5
- nftables firewall (NixOS port parity + tailscale0 trusted, dhcp allowed)
- sshd now uses the NixOS host key from /persist/etc/ssh → host identity
  of .66 stable across NixOS↔finix (key churn fixed)
- tailnet hosts entries (forgejo / syncthing-server / syncthing-desktop)
- state binds: /persist/var/lib/{forgejo,postgresql,private,tailscale,
  btrbk} → /var/lib/*; mounts: /home @home + Music/DCIM/Pictures + /btrfs
- trialSeconds 600 → 1800 (services need room; 10-min window was
  validated 3×)

Dropped (removed from NixOS server config too): docker/podman (host.nix,
dev.nix, impermanence /var/lib/docker) and everything jellyfin. Data still
on disk: /persist/var/lib/docker, @jellyfin subvol — delete manually when
ready.

Validated on metal, two full NixOS→finix→NixOS round-trips (~50s each
way, host key stable — no known_hosts churn, tailnet IP kept):

- boot #1: everything up except n8n (see production bugs below) + nginx
  403 (Host header vs syncthing's GUI host-check → now pass $proxy_host)
- boot #2 (fixes baked): ALL services running unattended — forgejo :3000
  + git-ssh :2222 (real repos), postgres 16.14 on the live cluster, n8n
  /healthz 200, syncthing via nginx :80 → 200, tailscaled same tailnet IP
  100.105.204.116, mediamtx :4200, nft ruleset loaded, btrbk end-to-end
  (real snapshots @dcim/@music), auto-return + keep marker + manual
  return all still good; NixOS healthy after both returns (0 failed
  units)

### Production bugs the trial UNCOVERED (broken under NixOS all along)

1. **n8n dead since ~Oct 2025**: empty community-package dir
   (.n8n/nodes/node_modules/@searchapi/…, no package.json) crashes the
   loader at startup → systemd had been silently crash-looping. Moved the
   empty dir aside (→ .n8n/broken-searchapi-*), n8n then ran ~30
   pending DB migrations and came up. Fixed for BOTH OSes (same state).
   finix additionally needs the /var/lib/n8n → /var/lib/private/n8n
   symlink (systemd StateDirectory layout) — baked into the n8n-state
   task.
2. **btrbk never ran**: /btrfs/_snapshots didn't exist and neither btrbk
   nor the NixOS module creates it → every timer run aborted. Created the
   dir once (shared state); snapshots verified under finix, NixOS timer
   will succeed from tonight.

## Upstream finix bugs/gaps to report

- `modules/finit/mount.nix` only generates mount tasks for `neededForBoot`
  filesystems — everything else is written to /etc/fstab and **never
  mounted**. Workaround: neededForBoot=true on every mount we need.
- `modules/boot/initrd.nix` maps every neededForBoot fs to
  `supportedFilesystems.<fsType>` — bind mounts default to fsType "auto"
  which is not a valid attr there. Workaround: declare binds fsType=btrfs
  (mount.nix ignores fsType for binds).
- `modules/networking/default.nix` seeds networking.hosts with REVERSED
  name→IP entries (localhost = [127.0.0.1]) while docs + renderer are
  IP-keyed → invalid /etc/hosts lines, localhost doesn't resolve (breaks
  postgres' default listen_addresses). Workaround in common.nix: blank the
  bad keys (mkForce []) + correct IP-keyed entries.
- openssh settings render list values space-joined on ONE line — two
  HostKey paths produce an invalid sshd_config. Workaround: single-entry
  list.
- dhcpcd module: forking + pidfile tracking never latches (tracked pid 0,
  restart loop). Workaround in common.nix: run foreground `-B` (mkForce).
- No default PATH for finit-spawned processes and for the initrd's
  standalone `sh` (bit us repeatedly; also affects interactive ssh login
  shells — worth checking finix's profile/env setup for a proper fix).
- **LANDMINE — `programs.limine`**: finix upstream ships a Limine module
  that is a fork of the NixOS installer using the SAME ESP paths
  (/boot/limine/limine.conf, \efi\limine\BOOTX64.EFI) and it prunes files
  it didn't write. Enabling it on the shared ESP would overwrite the NixOS
  menu and delete NixOS kernels — i.e. destroy the rescue path. Never
  enable it here; the ESP island (finix-server-boot) fills its role.

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

Restructured 2026-07-15 (post-promote; store-path-identical — topLevel
still 7jhzs63m…): finix/ now mirrors the repo's hosts/+modules/ shape.
finix stays its own module universe (finit option tree — ./modules/* at
the repo root can never be imported here); sharing happens via the
nixpkgs pin, key files, and (future) a facts.nix.

- `finix/default.nix` — thin composer: pkgs (allowUnfree n8n), systems,
  drivers, package exports; interface to flake.nix unchanged
- `finix/lib/mk-system.nix` — mkFinixSystem builder (baseline modules +
  modules/common.nix)
- `finix/lib/esp-island.nix` — espIslandScript + finix-server-boot driver
  (the boot path; prepends intel-ucode.img per slot)
- `finix/lib/deploy.nix` — SSH config-only deploy driver
- `finix/modules/common.nix` — shared baseline + upstream-bug workarounds
- `finix/hosts/y0usaf-server/{persistent,services}.nix` — the server
- `finix/attic/` — retired kexec era, still buildable: server-vm.nix,
  server-trial.nix, drivers.nix (beacon initrd, trial + persistent kexec,
  VM runner)
- flake outputs: `finixConfigurations.y0usaf-server` (first-class),
  packages finix-server-{persistent,persistent-deploy,boot} + attic
  {vm,trial,persistent-kexec}
- `hosts/y0usaf-server/finix-guard.nix` — NixOS side (watchdog arming,
  kexec-tools); still deployed; kexec arming retirable at next NixOS
  deploy (keep Runtime/RebootWatchdogSec — they guard NixOS itself)


## Server facts

- disk: /dev/sda2 btrfs UUID 9dfc38c4-5c75-471d-9106-80ff9175ab92,
  subvols @nix @persist @home @music @dcim @pictures @jellyfin ...
- NixOS kernel 7.1.3 == trial kernel (pinned linuxPackages_latest; the
  match was needed during debugging, probably relaxable now)
- NIC eth0 (r8169), DHCP gives .66 (also the static fallback)
- watchdog: intel_oc_wdt (iTCO blacklisted both sides)
- CPU: Alder Lake-N; BIOS microcode 0x1a is ancient/unstable — direct
  boots MUST load 0x21+ via early initrd cpio (island installer + bridge
  entry both handle this; incident #2)
- `server` ssh alias = y0usaf-server hostname (only resolves under NixOS);
  finix trial = y0usaf@192.168.2.66

## Next steps (→ DIRECTION stages)

DONE 2026-07-14/15: NixOS deploy (docker removal), two verified trial
round-trips, 24h soak accepted, persistent Finix booted via guarded kexec,
SSH deploy/test activation exercised without kexec, stage-3 recon +
ESP-island tooling built, and first contact (see incident log): BootNext
proven, first direct finix firmware boot green, rescue drill passed, stale
default_entry scrubbed → unattended boots deterministically NixOS.

Stage-3 order of operations (updated after incident #2):

1. DONE 2026-07-15: kmsg flight recorder + boot breadcrumbs + initrd/stage-2
   kmsg markers ported from server-trial.nix into server-persistent.nix.
   Logs → /persist/finix-boot/ (kmsg-*.log + boot-*.log, newest 20 kept;
   finix-trial/ stays trial-only). No netconsole/beacon by design.
2. DONE 2026-07-15 ~04:55Z: island install + official oneshot GREEN (see
   checklist). That boot then froze at 10:29Z → incident #2 → microcode
   root cause found and fixed; re-oneshot 13:28Z green with 0x21 loaded.
   Box UP on the island, BootOrder still NixOS-first.
3. DONE 2026-07-15 13:35Z: island→island warm reboot (oneshot FROM the
   island) green on fixed microcode — 00:19 pattern retired.
4. DONE 2026-07-15 ~13:37Z: PROMOTE. BootOrder 0000,0003,0002,0001
   (Finix-first). User accepted the freeze-recurrence risk in lieu of a
   pre-promote soak; watch continues post-promote (syslog heartbeat,
   initctl status, tailnet liveness).
5. Deploy the NixOS config once (bridge-entry ucode module + anything
   pending) — keeps the console fallback path microcode-correct too.
6. Remaining drills: power-cut test (hard reset → island → deadman →
   green unattended) and the post-promote `sudo boot-nixos` → NixOS →
   plain reboot → island round-trip.
7. Housekeeping: BIOS "AC power loss → power on" (+ optional smart plug
   = remote unbrick, matters MORE now that finix is default); tailnet
   ACL decision (accept vs check+checkPeriod); one end-to-end `ssh
   rescue` browser check; desktop rebuild for the aliases; postgres
   REFRESH COLLATION VERSION.
8. DONE 2026-07-15 ~01:20 EDT: btrbk-via-cron + DHCP renewal both proven
   on the island boot (induced; see checklist). Tonight's midnight cron
   fire is a free double-check.
9. File upstream issues (mount.nix, initrd bind fsType, hosts reversal,
   HostKey join, dhcpcd, PATH, programs.limine ESP collision, and
   consider: initrd should support early-microcode prepend natively) —
   all have in-tree workarounds.
9. Housekeeping when confident: delete `/persist/var/lib/docker`,
   `@jellyfin`, stale `/persist/var/lib/{acme,bayt,blocky}`,
   `.n8n/broken-searchapi-*`; relax the pinned kernel match if desired;
   retire the kexec drivers to an attic note once the island is default.
