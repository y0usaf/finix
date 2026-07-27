# Shared base for all finix server systems (VM and bare metal).
{
  config,
  lib,
  pkgs,
  ...
}: {
  time.timeZone = "America/Toronto";

  # finix's networking module seeds networking.hosts with reversed
  # name->IP entries ("localhost = [127.0.0.1]") while the renderer and the
  # option docs are IP-keyed - the defaults produce invalid /etc/hosts
  # lines, breaking localhost resolution (which e.g. postgres' default
  # listen_addresses depends on). Blank the bad keys (empty lists are
  # filtered out of the generated file) and supply correct IP-keyed
  # entries. TODO: report upstream.
  networking.hosts = {
    localhost = lib.mkForce [];
    "${config.networking.hostName}" = lib.mkForce [];
    "127.0.0.1" = ["localhost"];
    "::1" = ["localhost"];
    "127.0.0.2" = [config.networking.hostName];
  };

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
        AuthorizedKeysFile = [
          ".ssh/authorized_keys"
          "/etc/ssh/authorized_keys.d/%u"
        ];
        # Both the VM and the bare-metal trial run tmpfs roots: PAM rejects
        # accounts without a persistent shadow entry there (observed as
        # pubkey "Permission denied" on metal), and StrictModes trips over
        # store-backed paths. TODO: revisit for the persistent-root system.
        UsePAM = false;
        StrictModes = false;
      };
    };
  };

  # Upstream runs dhcpcd as a forking service with pidfile tracking, but
  # finit never latches onto the forked pid (tracked pid stays 0), loops
  # restarts, and marks the service crashed while the real daemon keeps the
  # lease. Run it in the foreground (-B) under direct supervision instead.
  # TODO: report/upstream a fix in finix's dhcpcd module.
  finit.services.dhcpcd = {
    command = lib.mkForce (
      "${lib.getExe config.services.dhcpcd.package} -B "
      + lib.escapeShellArgs config.services.dhcpcd.extraArgs
    );
    type = lib.mkForce null;
    pid = lib.mkForce null;
  };

  programs = {
    bash.enable = true;
    sudo.enable = true;
  };

  # Keep both the desktop key and the server's existing rescue key available
  # while the persistent system's SSH ownership checks are being tightened.
  environment = {
    etc."ssh/authorized_keys.d/y0usaf".text = ''
      ${lib.removeSuffix "\n" (builtins.readFile ../../hosts/y0usaf-desktop/user-ssh.pub)}
      ${lib.removeSuffix "\n" (builtins.readFile ../../hosts/y0usaf-framework/user-ssh.pub)}
      ${lib.removeSuffix "\n" (builtins.readFile ../../hosts/y0usaf-server/user-ssh.pub)}
      ${lib.removeSuffix "\n" (builtins.readFile ../../hosts/android-phone/user-ssh.pub)}
    '';
    etc.sudoers.text = lib.mkAfter ''
      y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
    '';
    systemPackages = with pkgs; [
      curl
      iproute2
      iputils
      procps
      util-linux
      vim
    ];
  };

  users.users.y0usaf = {
    isNormalUser = true;
    home = "/home/y0usaf";
    shell = "${pkgs.bashInteractive}/bin/bash";
    extraGroups = ["wheel"];
    # ***REMOVED*** for local console login only; sshd has
    # PasswordAuthentication disabled. TODO: read hash from /persist/secrets
    # once the bare-metal system graduates from trial status.
    password = "***REMOVED***";
  };
}
