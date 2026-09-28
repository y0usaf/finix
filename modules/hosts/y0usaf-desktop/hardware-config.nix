{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";
  btrfs = (import ../shared.nix {inherit lib pkgs;}).btrfs diskUuid ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  cfg = config.programs.limine;
in {
  finix.diagnostics = {
    inherit diskUuid;
    fallbackDevices = ["/dev/nvme0n1p5"];
  };

  user.dev.prompts.host = ["The GPU is an NVIDIA GeForce RTX 4090."];

  hardware = {
    firmware = [pkgs.linux-firmware];
    cpu.amd.updateMicrocode = true;
    nvidia = {
      enable = true;
      gsp.enable = false;
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [config.boot.kernelPackages.zenpower config.hardware.nvidia.package.mod];
    initrd.availableKernelModules = [
      "nvme"
      "thunderbolt"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
      "zenpower"
      "igc"
    ];
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
      "console=tty0"
      "usbcore.autosuspend=-1"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_EnableResizableBar=1"
      "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
      "nvidia_modeset.disable_vrr_memclk_switch=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    ];
    loader.efi.canTouchEfiVariables = true;
  };

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

  programs.limine = {
    enable = true;

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

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=4G"];
    };

    "/tmp" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=1777" "size=16G" "nosuid" "nodev" "strictatime"];
      neededForBoot = true;
    };

    "/nix" = btrfs "subvol=@nix";
    "/persist" = btrfs "subvol=@persist";
    "/home" = btrfs "subvol=@home";
    "/btrfs" = btrfs "subvolid=5";

    "/boot" = {
      device = "/dev/disk/by-uuid/31F2-1AE7";
      fsType = "vfat";
      options = ["fmask=0077" "dmask=0077" "noatime"];
      neededForBoot = true;
    };

    "/home/y0usaf/.local/share/Steam" = btrfs "subvol=@steam";
    "/home/y0usaf/dev" = btrfs "subvol=@dev";
    "/home/y0usaf/Pictures" = btrfs "subvol=@pictures";
    "/home/y0usaf/DCIM" = btrfs "subvol=@dcim";
    "/home/y0usaf/Music" = btrfs "subvol=@music";
  };

  user = {
    appearance.dpi = 109;

    ui.tomoe.displays = {
      "DP-4" = {
        mode = [5120 1440];
        icc = "${pkgs.runCommand "ls49ag95.icc" {} "${lib.getExe' pkgs.colord "cd-create-profile"} -o $out ${./ls49ag95.iccprofile.xml}"}";
      };
      "HDMI-A-2" = {
        mode = [1920 1080 60];
        position = [5120 0];
      };
    };
  };
}
