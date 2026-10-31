{ pkgs, lib, config, ompBox, ... }:
let
  user = ompBox.user;
  home = "/home/${user}";
  mountPoint = p: p;
in {
  system.stateVersion = "24.05";

  microvm = {
    hypervisor = "qemu";
    mem = 1024;
    vcpu = 2;
    shares =
      [ { tag = "ro-store"; source = "/nix/store"; mountPoint = "/nix/.ro-store"; } ]
      ++ map (p: { tag = "share-${builtins.hashString "sha1" p}"; source = p; mountPoint = p; proto = "9p"; }) ompBox.shares;
    interfaces = [ ];
    qemu.extraArgs = [
      "-netdev" "user,id=net0,hostfwd=tcp:127.0.0.1:22422-:22"
      "-device" "virtio-net-pci,netdev=net0"
    ];
  };

  environment.systemPackages = with pkgs; [ python3 chromium git ripgrep curl ];
  documentation.enable = false;
  boot.kernelParams = [ "console=ttyS0" "loglevel=4" ];

  networking.hostName = "omp-box";
  networking.firewall.enable = false;
  networking.useNetworkd = true;
  systemd.network.networks."10-eth0" = {
    matchConfig.Driver = "virtio_net";
    networkConfig.Address = [ "10.0.2.15/24" ];
    networkConfig.Gateway = "10.0.2.2";
    networkConfig.DNS = [ "10.0.2.3" ];
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

  fileSystems."${home}/.omp/run" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=0700" "uid=1001" "gid=100" "size=512M" ];
  };
  fileSystems."${home}/.omp/agent" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "mode=0700" "uid=1001" "gid=100" "size=2G" ];
  };

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
      install -o 1001 -g 100 -m 600 ${ompBox.files.appendSystem} "$dst/APPEND_SYSTEM.md"
    '';
  };
}
