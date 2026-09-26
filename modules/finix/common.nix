{
  config,
  lib,
  pkgs,
  ...
}: {
  time.timeZone = "America/Toronto";

  networking.hosts = {
    localhost = lib.mkForce [];
    "${config.networking.hostName}" = lib.mkForce [];
    "127.0.0.1" = ["localhost"];
    "::1" = ["localhost"];
    "127.0.0.2" = [config.networking.hostName];
  };

  services.openssh.settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
    AuthorizedKeysFile = [
      ".ssh/authorized_keys"
      "/etc/ssh/authorized_keys.d/%u"
    ];
    UsePAM = false;
    StrictModes = false;
  };

  finit.services.dhcpcd = {
    command = lib.mkForce (
      "${lib.getExe config.services.dhcpcd.package} -B "
      + lib.escapeShellArgs config.services.dhcpcd.extraArgs
    );
    type = lib.mkForce null;
    pid = lib.mkForce null;
  };

  environment = {
    etc.sudoers.text = lib.mkAfter ''
      y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
    '';
    shells = [
      "/run/current-system/sw/bin/rush"
      "${pkgs.rush}/bin/rush"
      "/run/current-system/sw/bin/ash"
      "${pkgs.ash}/bin/ash"
    ];
    systemPackages = [
      pkgs.curl
      pkgs.iproute2
      pkgs.iputils
      pkgs.procps
      pkgs.util-linux
      pkgs.vim
      pkgs.rush
      pkgs.ash
    ];
  };

  users.users.y0usaf = {
    isNormalUser = true;
    home = "/home/y0usaf";
    shell = "${pkgs.rush}/bin/rush";
    extraGroups = ["wheel"];
    passwordFile = "/persist/secrets/password-hashes/y0usaf";
  };
}
