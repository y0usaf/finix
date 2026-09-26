{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.programs.limine;
in {
  providers.bootloader.installHook = lib.mkForce (pkgs.replaceVarsWith {
    src = pkgs.runCommand "limine-install.py" {} ''
      sed -e 's/+NixOS {group_name}/+finix {group_name}/' \
          -e 's/NixOS boot entries/finix boot entries/g' \
          -e '/specialisations = bootjson\[/a\    specialisations = {k: v for k, v in specialisations.items() if k != "vbios-maintenance"}' \
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

  boot.bootspec.enable = true;

  boot.loader.efi.canTouchEfiVariables = true;

  hardware.cpu.amd.updateMicrocode = true;

  programs.limine = {
    enable = true;

    enrollConfig = true;
    maxGenerations = 20;

    extraEntries = ''
      /Finix golden
        protocol: linux
        comment: pinned fallback from the running system
        kernel_path: boot():/EFI/finix/kernels/golden/kernel
        cmdline: init=/nix/store/ralz7prz3545kixkfwag61ky42z1j8b9-finix-system/init nvidia-drm.modeset=1 nvidia-drm.fbdev=1 nvidia.NVreg_UsePageAttributeTable=1 nvidia.NVreg_EnableResizableBar=1 nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1 nvidia_modeset.disable_vrr_memclk_switch=1 nvidia.NVreg_TemporaryFilePath=/var/tmp amd_pstate=active mitigations=off console=tty0 panic=30 oops=panic softlockup_panic=1 hung_task_panic=1
        module_path: boot():/EFI/finix/kernels/golden/initrd

      /Vinix
        protocol: limine
        comment: vinix nightly-2026-09-07 (vanilla ISO kernel+initramfs)
        kernel_path: boot():/EFI/vinix/vinix
        module_path: boot():/EFI/vinix/initramfs.tar
        resolution: 1024x768x32
        kaslr: no
    '';

    settings = {
      timeout = 5;
      hash_mismatch_panic = true;
      editor_enabled = false;
    };
  };
}
