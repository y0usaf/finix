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

  services.openssh.settings = {
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

  # rush is a POSIX shell with no programs.rush module in finix, so its
  # system-level wiring (login shell + /etc/shells) is hand-rolled here.
  # modules/shell/rush/config.nix owns the user rc (desktop only). rush reads
  # /etc/profile for system env via ~/.config/rush/profile.rush (login).

  environment = {
    etc.sudoers.text = lib.mkAfter ''
      y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
    '';
    shells = [
      "/run/current-system/sw/bin/rush"
      "${pkgs.rush}/bin/rush"
    ];
    systemPackages = [
      pkgs.curl
      pkgs.iproute2
      pkgs.iputils
      pkgs.procps
      pkgs.util-linux
      pkgs.vim
      pkgs.rush
    ];
  };

  users.users.y0usaf = {
    isNormalUser = true;
    home = "/home/y0usaf";
    shell = "${pkgs.rush}/bin/rush";
    extraGroups = ["wheel"];
    # Password hash is supplied from the persistent secret store for local
    # console login only; sshd has PasswordAuthentication disabled. The file
    # must exist before rebuilding finix on bare metal.
    passwordFile = "/persist/secrets/password-hashes/y0usaf";
  };
}
