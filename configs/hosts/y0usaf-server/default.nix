{
  lib,
  flakeInputs,
  ...
}: {
  imports = [
    ../../../nixos
    ./hardware-configuration.nix
    ./impermanence.nix
    ({lib, ...}: let
      btrfsDevice = "/dev/disk/by-uuid/9dfc38c4-5c75-471d-9106-80ff9175ab92";
    in {
      # Recreate @home from @home-blank on each boot (impermanence README pattern).
      # This keeps /home ephemeral without moving it to tmpfs.
      boot.initrd.postDeviceCommands = lib.mkAfter ''
        mkdir -p /btrfs_tmp
        mount -t btrfs -o subvolid=5 ${btrfsDevice} /btrfs_tmp

        delete_subvolume_recursively() {
          IFS=$'\n'
          for subvolume in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$subvolume"
          done
          btrfs subvolume delete "$1" >/dev/null 2>&1 || true
        }

        if [ ! -d /btrfs_tmp/@home-blank ]; then
          if [ -d /btrfs_tmp/@home ]; then
            btrfs subvolume snapshot -r /btrfs_tmp/@home /btrfs_tmp/@home-blank
          else
            btrfs subvolume create /btrfs_tmp/@home-blank
          fi
        fi

        if [ -d /btrfs_tmp/@home ]; then
          delete_subvolume_recursively /btrfs_tmp/@home
        fi

        btrfs subvolume snapshot /btrfs_tmp/@home-blank /btrfs_tmp/@home
        umount /btrfs_tmp
      '';
    })
    (flakeInputs.self + /configs/users/server.nix)
  ];

  hostname = "y0usaf-server";
  trustedUsers = ["y0usaf"];
  homeDirectory = "/home/y0usaf";
  stateVersion = "24.11";
  timezone = "America/Toronto";
  var-cache = true;
  core.graphicalDesktop.headless = true;
  hardware = {
    bluetooth = {
      enable = false;
    };
    cpu.intel.enable = true;
    nvidia = {
      enable = false;
      cuda.enable = false;
    };
    amdgpu.enable = false;
  };
  services = {
    btrbk-snapshots.enable = true;
    docker.enable = true;
    waydroid.enable = false;
    controllers.enable = false;
    mediamtx.enable = true;
    n8n = {
      enable = true;
      openFirewall = true;
    };
    forgejo.enable = true;
    openssh.enable = lib.mkForce true;
    tailscale.enableVPN = true;
    syncthing-proxy = {
      enable = true;
      virtualHostName = "syncthing-server";
    };
  };

  boot.loader.limine.secureBoot.enable = lib.mkForce false;

  networking = {
    nameservers = ["1.1.1.1" "8.8.8.8"];
    useDHCP = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443 2222 3000 22000];
      allowedUDPPorts = [22000 21027];
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      FallbackDNS = ["1.1.1.1" "8.8.8.8"];
      DNSSEC = "false";
    };
  };
}
