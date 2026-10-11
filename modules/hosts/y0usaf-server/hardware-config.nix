{
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  btrfs = (import ../shared.nix {inherit lib pkgs;}).btrfs diskUuid;
in {
  finix.diagnostics = {
    inherit diskUuid;
    fallbackDevices = ["/dev/sda2" "/dev/nvme0n1p2"];
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "sd_mod"
      "nvme"
      "r8169"
      "igc"
      "e1000e"
    ];
    kernelModules = [
      "intel_oc_wdt"
      "r8169"
      "igc"
      "e1000e"
    ];
    supportedFilesystems.efivarfs.enable = true;
    kernelParams = [
      "console=tty0"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
    ];
  };

  environment.etc."modprobe.d/finix-server-blacklist.conf".text = ''
    blacklist iTCO_wdt
    blacklist iTCO_vendor_support
  '';

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["mode=755" "size=2G"];
    };

    "/nix" = btrfs ["noatime"] "subvol=@nix";
    "/persist" = btrfs ["compress=zstd" "noatime"] "subvol=@persist";
    "/home" = btrfs ["compress=zstd" "noatime"] "subvol=@home";
    "/home/y0usaf/Music" = btrfs [] "subvol=@music";
    "/home/y0usaf/DCIM" = btrfs [] "subvol=@dcim";
    "/home/y0usaf/Pictures" = btrfs [] "subvol=@pictures";
    "/btrfs" = btrfs [] "subvolid=5";

    "/boot" = {
      device = "/dev/disk/by-uuid/41B0-E342";
      fsType = "vfat";
      options = ["umask=0077" "noatime"];
      neededForBoot = true;
    };
  };

  finit = {
    services.watchdog-keepalive = {
      description = "persistent watchdog keepalive";
      command = "${pkgs.writeShellScript "persistent-watchdog-keepalive" ''
        set -u
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.kmod]}

        ${pkgs.kmod}/bin/modprobe intel_oc_wdt 2>/dev/null || true

        for _ in $(seq 1 30); do
          set -- /dev/watchdog[0-9]*
          [ -c "$1" ] && break
          sleep 1
        done

        devs=()
        for d in /dev/watchdog[0-9]*; do
          [ -c "$d" ] || continue
          if exec {fd}>"$d"; then
            devs+=("$fd")
          fi
        done

        if [ "''${#devs[@]}" -eq 0 ]; then
          echo "watchdog-keepalive: no watchdog devices found" >&2
          exit 1
        fi

        trap 'for fd in "''${devs[@]}"; do printf V >&"$fd"; done; exit 0' TERM INT
        while true; do
          for fd in "''${devs[@]}"; do
            printf '\0' >&"$fd"
          done
          sleep 5
        done
      ''}";
      log = true;
    };
  };
}
