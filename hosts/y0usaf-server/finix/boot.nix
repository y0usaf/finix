# Stage-3 boot takeover for y0usaf-server — STAGED, NOT ARMED.
#
# Current era (takeover = false): NixOS owns /boot/limine and the "Limine"
# EFI entry; finix boots from its self-contained \EFI\finix island
# (finix/esp-island.nix, `nix run .#finix-server-boot`), which has been
# BootOrder head since the 2026-07-15 promote. This module contributes
# NOTHING while the flag is off — the upstream limine module is inert
# unless programs.limine.enable is true (verified in the pin:
# modules/programs/limine/default.nix, whole config block is mkIf cfg.enable).
# It is imported anyway so it keeps evaluating on every deploy instead of
# rotting until the day it is needed.
#
# Flipping takeover = true hands /boot/limine to finix, exactly as the
# desktop did on 2026-07-27 (hosts/y0usaf-desktop/finix/boot.nix).
#
# ── WHAT THE FLIP DESTROYS ────────────────────────────────────────────────
# limine-install.py walks the whole install dir, marks every pre-existing
# file for deletion, then writes its own limine.conf from
# /nix/var/nix/profiles/system generations (which on this box are FINIX
# generations). So the flip deletes the NixOS generation kernels and the
# NixOS entries in /boot/limine. The NixOS rescue OS stops being reachable
# from the boot menu the moment the first `stc boot` runs.
#
# ── WHAT SURVIVES THE FLIP ────────────────────────────────────────────────
# The ESP island lives at /boot/EFI/finix — a different directory, never
# touched by limine-install.py — and keeps its own "Finix" EFI boot entry.
# After the flip the island is the fallback that NixOS used to be. That is
# what makes this recoverable on a box with no console: a broken
# limine.conf still leaves an independent, firmware-level path into a
# known-good finix slot.
#
# ── DEADMAN CAVEAT (READ BEFORE FLIPPING) ─────────────────────────────────
# persistent.nix's bootnext-deadman arms BootNext at the EFI entry named
# "Limine" and calls that "fall home to NixOS". After the takeover that
# entry boots the FINIX-owned limine.conf, so the deadman would fall home
# into the same system that just failed — it becomes decorative. Retarget
# it at the "Finix" island entry (or the island's golden slot) as part of
# the flip; the same applies to the `boot-nixos` helper in persistent.nix,
# which becomes a lie and should be renamed/removed.
#
# ── FLIP RUNBOOK ──────────────────────────────────────────────────────────
# See finix/NOTES.md "2026-07-29 SERVER — takeover staged".
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  # ── THE SWITCH ─────────────────────────────────────────────────────────
  # false = island era (current, safe, remote-recoverable)
  # true  = finix owns /boot/limine (one-way for the NixOS rescue path)
  takeover = false;

  cfg = config.programs.limine;
in {
  config = lib.mkIf takeover {
    # installHook override: upstream limine-install.py hardcodes the
    # generation group header as "/+NixOS default profile". The per-gen
    # labels already say finix (bootspec.nix); patch the header to match.
    # Same replaceVarsWith as upstream, patched script. Local override
    # only — retire when upstream makes the name configurable.
    providers.bootloader.installHook = lib.mkForce (pkgs.replaceVarsWith {
      src = pkgs.runCommand "limine-install.py" {} ''
        sed -e 's/+NixOS {group_name}/+finix {group_name}/' \
            -e 's/NixOS boot entries/finix boot entries/g' \
            ${flakeInputs.finix}/modules/programs/limine/limine-install.py > $out
      '';
      isExecutable = true;
      replacements = {
        python3 = pkgs.python3.withPackages (python-packages: [python-packages.psutil]);
        configPath = pkgs.writeText "limine-install.json" (builtins.toJSON {
          inherit
            (cfg)
            additionalFiles
            biosDevice
            biosSupport
            efiSupport
            enrollConfig
            extraEntries
            force
            partitionIndex
            settings
            validateChecksums
            secureBoot
            ;

          nixPath = config.services.nix-daemon.package;
          efiBootMgrPath = pkgs.efibootmgr;
          liminePath = cfg.package;
          efiMountPoint = config.boot.loader.efi.efiSysMountPoint;
          inherit (config) fileSystems;
          inherit (config.boot.loader.efi) canTouchEfiVariables;
          efiRemovable = cfg.efiInstallAsRemovable;
          maxGenerations =
            if cfg.maxGenerations == null
            then 0
            else cfg.maxGenerations;
          hostArchitecture = pkgs.stdenv.hostPlatform.parsed.cpu;
          fwupdEfiPath = config.services.fwupd.package or null;
        });
      };
    });

    # limine-install.py reads boot.json (RFC-0125 org.nixos.bootspec.v1)
    # from every generation link; finix emits it when this is on.
    boot.bootspec.enable = true;

    # Let the installer create/update the "Limine" EFI entry and guarantee
    # the efivarfs mount (persistent.nix already needs efivars for the
    # deadman, so this is a no-op in practice).
    boot.loader.efi.canTouchEfiVariables = true;

    # Early Intel microcode: the island loads intel-ucode.img as a separate
    # Limine module (ADL-N BIOS ships 0x1a; incident #2 froze the box until
    # 0x21 was prepended). limine-install.py has no ucode concept, so bake
    # it into the initrd instead — native since upstream PR #103, in pin.
    # LOAD-BEARING: a takeover boot without this is incident #2 again.
    hardware.cpu.intel.updateMicrocode = true;

    programs.limine = {
      enable = true;

      # Keep the island era's tamper-evidence: the conf hash is enrolled
      # into BOOTX64.EFI and a mismatch panics. Secure Boot stays off in
      # firmware (headless box, no enrolment ceremony).
      enrollConfig = true;
      maxGenerations = 20;

      # Console-less recovery: keep an explicit entry that chainloads the
      # island's own Limine, so a human at a rescue console (or a bad
      # default_entry) still has one keypress into the golden slot. Lives
      # outside the managed section, so renders preserve it.
      extraEntries = ''
        /Finix ESP island (fallback)
          protocol: efi
          comment: chainload \EFI\finix\BOOTX64.EFI (island slots, incl. golden)
          path: boot():/EFI/finix/BOOTX64.EFI
      '';

      settings = {
        # Headless: nobody is watching the menu. Long enough that a serial
        # console can interrupt, short enough not to stall unattended boots.
        timeout = 5;
        hash_mismatch_panic = true;
        # default false; stated explicitly — the editor is an
        # init=/bin/sh root vector on a box exposed to the tailnet.
        editor_enabled = false;
      };
    };
  };
}
