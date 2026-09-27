{
  config,
  lib,
  pkgs,
  ...
}: let
  user = config.user.name;
  persistedSshDir = "/persist/etc/ssh";
in {
  time.timeZone = "America/Toronto";

  networking.hosts = {
    localhost = lib.mkForce [];
    "${config.networking.hostName}" = lib.mkForce [];
    "127.0.0.1" = ["localhost"];
    "::1" = ["localhost"];
    "127.0.0.2" = [config.networking.hostName];
  };

  boot.initrd.supportedFilesystems.btrfs.enable = true;

  services = {
    mdevd.enable = true;
    sysklogd.enable = true;
    dhcpcd.enable = true;
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
        KbdInteractiveAuthentication = false;
        HostKey = lib.mkForce ["${persistedSshDir}/ssh_host_ed25519_key"];
        AuthorizedKeysFile = lib.mkForce ["${persistedSshDir}/authorized_keys.d/%u"];
        UsePAM = lib.mkForce true;
        StrictModes = lib.mkForce true;
      };
    };
    nix-daemon = {
      enable = true;
      settings.trusted-users = lib.mkForce ["root" user];
    };
  };

  programs.bash.enable = true;

  manzil.forceByDefault = true;

  finit = {
    services.dhcpcd = {
      command = lib.mkForce (
        "${lib.getExe config.services.dhcpcd.package} -B "
        + lib.escapeShellArgs config.services.dhcpcd.extraArgs
      );
      type = lib.mkForce null;
      pid = lib.mkForce null;
    };
    tasks = {
      remount-nix-store.enable = false;
      ssh-keygen.command = lib.mkForce (pkgs.writeShellScript "check-host-keys" ''
        [ -s ${persistedSshDir}/ssh_host_ed25519_key ]
      '');
    };
  };

  system.activation.scripts.persistentSshAuthorizedKeys = {
    deps = ["etc"];
    text = ''
      ${pkgs.coreutils}/bin/install -d -m 0755 ${persistedSshDir}/authorized_keys.d
      ${pkgs.coreutils}/bin/install -m 0644 -o root -g root \
        /etc/ssh/authorized_keys.d/${user} \
        ${persistedSshDir}/authorized_keys.d/${user}
    '';
  };

  environment = {
    etc = {
      sudoers.text = lib.mkAfter ''
        y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
      '';
      "ssh/authorized_keys.d/y0usaf".text = ''
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-desktop/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-framework/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-server/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/android-phone/user-ssh.pub)}
      '';
    };
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
    passwordFile = lib.mkForce "/persist/secrets/password-hashes/${user}";
  };
}
