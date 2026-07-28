# Boot ownership for y0usaf-desktop: finix owns /boot via the UPSTREAM
# programs.limine module (2026-07-27; replaces the custom single-Limine
# section writer — finix/limine-entries.nix is deleted).
#
# Why the NOTES.md landmine no longer applies HERE: the warning was
# "upstream limine uses the same ESP paths as NixOS's module and prunes
# what it didn't write → destroys the NixOS rescue path". The NixOS
# generations were already stripped from limine.conf in the single-Limine
# era, and Windows boots via its own EFI entry (Boot0001), not Limine —
# nothing left on this ESP to destroy. The SERVER keeps the ESP island;
# this module stays OFF there (headless: the BootNext deadman ceremony
# still earns its keep).
#
# Effect: switch-to-configuration switch|boot runs
# providers.bootloader.installHook (limine-install.py), which renders
# /boot/limine/limine.conf from /nix/var/nix/profiles/system generations
# and installs + enrolls \efi\limine\BOOTX64.EFI. `nh os switch` then IS
# the complete day-2 flow: build → activate (stc test) → new profile
# generation → stc boot (installHook). Rollback = pick an older
# generation at the Limine menu, exactly the NixOS model.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.programs.limine;

  # Mirror of upstream providers.bootloader.nix's limine-install.json.
  # Rebuilt here because the local installHook override below needs the
  # same configPath substitution.

  # Upstream limine-install.py hardcodes the generation group header as
  # "/+NixOS default profile" (and the start/end comments). The per-gen
  # labels already say "finix" (bootspec.nix); patch the header to match.
  # Local override only — retire when upstream makes the name configurable.
in {
  # installHook override: same replaceVarsWith as upstream, patched script.
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

  # Let the installer create/update the "Limine" EFI entry (Boot0000,
  # already exists) — also guarantees the efivarfs mount.
  boot.loader.efi.canTouchEfiVariables = true;

  # Early AMD microcode: the island loaded amd-ucode.img as a separate
  # Limine module; limine-install.py has no ucode concept, so bake it
  # into the initrd instead (PR #103, in pin). LOAD-BEARING on this box:
  # BIOS ships 0x0a601206, every island boot updated early to 0x0a60120a.
  hardware.cpu.amd.updateMicrocode = true;

  programs.limine = {
    enable = true;
    # Keep the island era's tamper-evidence: the conf hash is enrolled
    # into BOOTX64.EFI and a mismatch panics. Secure Boot stays off in
    # firmware; flipping secureBoot.enable later pulls in upstream's
    # assertion set (enroll + validateChecksums + no editor) itself.

    enrollConfig = true;
    maxGenerations = 20;
    settings = {
      timeout = 5;
      hash_mismatch_panic = true;
      # default false; stated explicitly — the editor is an init=/bin/sh
      # root vector.
      editor_enabled = false;
    };
  };
}
