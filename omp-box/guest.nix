{ pkgs, lib, config, ompBox, ... }:
let
  user = ompBox.user;
  home = "/home/${user}";
  mountPoint = p: p;
  fs9p = [ "trans=virtio" "version=9p2000.L" "msize=65536" "cache=loose" "x-systemd.after=systemd-modules-load.service" "x-initrd.mount" ];
in {
  system.stateVersion = "24.05";

  microvm = {
    hypervisor = "qemu";
    mem = 4096;
    vcpu = 4;
    shares =
      [ { tag = "ro-store"; source = "/nix/store"; mountPoint = "/nix/.ro-store"; } ]
      ++ map (p: { tag = "share-${builtins.substring 0 16 (builtins.hashString "sha1" p)}"; source = p; mountPoint = p; proto = "9p"; }) ompBox.shares
      ++ [ { tag = "shares"; source = ompBox.sharesDir; mountPoint = "/mnt/shares"; proto = "9p"; } ]
      ++ map (p: { tag = "cred-${builtins.substring 0 16 (builtins.hashString "sha1" p)}"; source = p; mountPoint = p; proto = "9p"; readOnly = true; }) ompBox.credentials
      ++ [ { tag = "host-ssh"; source = "${home}/.ssh"; mountPoint = "/mnt/host-ssh"; proto = "9p"; readOnly = true; } ];
    interfaces = [ ];
    qemu.extraArgs = [
      "-netdev" "user,id=net0,hostfwd=tcp:127.0.0.1:22422-:22"
      "-device" "virtio-net-pci,netdev=net0"
    ];
  };

  environment.systemPackages = with pkgs; [ ompBox.omp python3 chromium git ripgrep curl gh jq fd gnumake gcc ];
  documentation.enable = false;

  environment.interactiveShellInit = ''
    for f in "$HOME"/Tokens/*.txt; do
      [ -f "$f" ] || continue
      n=''${f##*/}; n=''${n%.txt}
      case $n in [0-9]* | *[!A-Za-z0-9_]*) continue ;; esac
      v=$(cat "$f") || continue
      export "$n=$v"
    done
    unset f n v
  '';


  boot.kernelParams = [ "console=ttyS0" "loglevel=4" ];

  networking.hostName = "omp-box";
  networking.firewall.enable = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.Driver = "virtio_net";
    networkConfig.Address = [ "10.0.2.15/24" ];
    networkConfig.Gateway = "10.0.2.2";
    networkConfig.DNS = [ "10.0.2.3" ];
    networkConfig.Domains = [ "home" ];
  };

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  users.groups.users.gid = 100;
  users.users.${user} = {
    isNormalUser = true;
    uid = 1001;
    group = "users";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ ./id_ed25519.pub ];
  };
  security.sudo.wheelNeedsPassword = false;

  fileSystems = lib.mkMerge (
    [ { "/nix/.ro-store".options = lib.mkForce fs9p; }
      { "${home}/.omp/run" = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "mode=0700" "uid=1001" "gid=100" "size=512M" ];
        };
      }
      { "${home}/.omp/agent" = {
          device = "tmpfs";
          fsType = "tmpfs";
          options = [ "mode=0700" "uid=1001" "gid=100" "size=2G" ];
        };
      }
    ]
  );

  systemd.services.omp-seed = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      dst=${home}/.omp/agent
      install -d -o 1001 -g 100 -m 700 "$dst"
      install -o 1001 -g 100 -m 600 ${ompBox.files.models} "$dst/models.json"
      install -o 1001 -g 100 -m 600 ${ompBox.files.settings} "$dst/settings.json"
      install -o 1001 -g 100 -m 600 ${ompBox.files.config} "$dst/config.yml"
      install -o 1001 -g 100 -m 600 ${ompBox.files.modelKeys} "$dst/models.yml"
      install -o 1001 -g 100 -m 600 ${ompBox.files.appendSystem} "$dst/APPEND_SYSTEM.md"

      for _ in $(seq 120); do [ -e /mnt/host-ssh/config ] && break; sleep 0.25; done
      install -d -o 1001 -g 100 -m 700 ${home}/.ssh
      for f in /mnt/host-ssh/config /mnt/host-ssh/known_hosts* /mnt/host-ssh/id_ed25519 /mnt/host-ssh/id_ed25519.pub; do
        if [ -e "$f" ]; then install -o 1001 -g 100 -m 600 "$f" ${home}/.ssh/; fi
      done
      printf 'Host github.com\n  StrictHostKeyChecking accept-new\n' >> ${home}/.ssh/config
    '';
  };
}
