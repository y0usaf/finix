# Bare-metal hardware config for y0usaf-server under finix.
# Mirrors hosts/y0usaf-server/hardware-configuration.nix but expressed
# through finix's filesystem + boot modules.
{
  config,
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  bootUuid = "41B0-E342";
  # Bare-metal finix stage 1 races mdevd/blkid symlink creation. aanderse's
  # finix-config hit the same bug and avoided /dev/disk/by-uuid for boot-time
  # filesystems. Use the stable kernel device nodes directly for now.
  # Current mapping on y0usaf-server: /dev/sda1 = ESP, /dev/sda2 = shared btrfs.
  diskDev = "/dev/sda2";
  bootDev = "/dev/sda1";
in {
  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "sd_mod"
        "virtio_pci"
        "virtio_blk"
        "nvme"
        # NIC drivers — without these, networking will never come up and
        # the box is unreachable even if userspace boots fine.
        "r8169" # Realtek RTL8111/8168 (this server)
        "igc" # Intel i225/i226 (common on mini-PCs)
        "e1000e" # Intel 1G PCIe (fallback)
      ];
      kernelModules = ["btrfs"];
    };
    # Non-initrd modules that must still ship in the system closure.
    # finix shrinks the module tree to only what's referenced here +
    # availableKernelModules, so anything omitted is literally absent.
    kernelModules = [
      "kvm-intel"
      "r8169"
      "igc"
      "e1000e"
    ];
    # Root is tmpfs; /nix, /persist, /home all live on btrfs.
    # loglevel=7 + earlycon gives maximal visibility on the VGA console
    # attached to the box; the VGA console is the only diagnostic channel
    # on this headless server since there is no serial.
    kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
      "loglevel=7"
      "earlycon"
      "panic=30" # reboot 30s after a panic, returning to NixOS via BootOrder
    ];
    supportedFilesystems.btrfs.enable = true;
    initrd.supportedFilesystems.btrfs.enable = true;
    # Do the full stage 1 mounting ourselves inside fileSystemImportCommands,
    # then keep the screen visible for 30s on either success or failure so the
    # human can read it before kernel panics.
    initrd.fileSystemImportCommands = ''
      set +e
      target=/dev/sda2
      echo "==== waiting for $target (up to 60s) ===="
      for i in $(seq 1 60); do
        [ -b "$target" ] && break
        sleep 1
      done
      if ! [ -b "$target" ]; then
        echo 'FATAL: target device never appeared'
        sleep 30
        exit 1
      fi
      echo "found $target, mounting /sysroot + subvols explicitly:"
      mkdir -p /sysroot
      mount -t tmpfs -o mode=755,size=2G none /sysroot; echo "tmpfs /sysroot: $?"
      mkdir -p /sysroot/nix
      mount -t btrfs -o subvol=@nix "$target" /sysroot/nix; echo "btrfs @nix /sysroot/nix: $?"
      mkdir -p /sysroot/persist
      mount -t btrfs -o subvol=@persist "$target" /sysroot/persist; echo "btrfs @persist /sysroot/persist: $?"
      echo '---- /sysroot ----'
      ls /sysroot
      echo '---- /sysroot/nix (top 10) ----'
      ls /sysroot/nix | head -10
      echo '---- /sysroot/nix/store finix entries ----'
      ls /sysroot/nix/store 2>/dev/null | grep -i finix | head
      echo '---- switch-root target ----'
      initpath=$(cat /proc/cmdline | tr ' ' '\n' | grep '^init=' | cut -d= -f2-)
      echo "init from cmdline: $initpath"
      echo "test -x /sysroot$initpath: $(test -x /sysroot$initpath && echo yes || echo NO)"
      ls -la /sysroot$initpath 2>&1 | head -3
      echo '==== 30s pause ===='
      sleep 30
      : # exit 0 so mount-all will also run (idempotent)
    '';
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=2G"];
    };

    "/nix" = {
      device = diskDev;
      fsType = "btrfs";
      # Minimal options for stage 1. Anything exotic (compress=zstd) can fail
      # silently in the initramfs mount helper. Re-apply desired options in
      # stage 2 / finit via a dedicated remount task if needed.
      options = ["subvol=@nix"];
      neededForBoot = true;
    };

    "/boot" = {
      device = bootDev;
      fsType = "vfat";
      options = ["fmask=0022" "dmask=0022"];
    };

    # /persist and /home are mounted by the impermanence activation script,
    # but we still declare them so finix knows they're neededForBoot.
    "/persist" = {
      device = diskDev;
      fsType = "btrfs";
      options = ["subvol=@persist"];
      neededForBoot = true;
    };
  };

  boot.loader.efi.efiSysMountPoint = "/boot";
  boot.loader.efi.canTouchEfiVariables = true;

  # Limine as bootloader (finix provides a provider).
  programs.limine = {
    enable = true;
    biosSupport = false;
    efiSupport = true;
    efiInstallAsRemovable = false;
    maxGenerations = 20;
    extraEntries = "";
  };
  providers.bootloader.backend = "limine";
}
