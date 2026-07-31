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
    # Still enabled with zsh as the login shell: this ships /etc/bashrc and
    # /etc/profile.d/bash.sh, and bash remains /bin/sh plus the fallback shell.
    bash.enable = true;
    sudo.enable = true;
  };

  # finix has no programs.zsh module (only bash and fish), and compat-import
  # drops `programs.*` from the NixOS tree anyway — so zsh's system-level
  # wiring is hand-rolled here. modules/shell/zsh/config.nix owns the user rc.
  #
  # /etc/zshenv is REQUIRED, not cosmetic. nixpkgs' zsh is built with a global
  # zshenv that does:  if /etc/NIXOS exists and /etc/zshenv is unreadable,
  # source /etc/set-environment. finix creates /etc/NIXOS but has no
  # /etc/set-environment (it uses /etc/profile.d instead), so without this file
  # every single zsh start prints:
  #   .../zsh-5.9.2/etc/zshenv:.:8: no such file or directory: /etc/set-environment
  # Providing the file takes the readable branch and silences the fallback.
  # System env still arrives the same way bash gets it: ~/.zprofile sources
  # /etc/profile under `emulate sh`.

  # Desktop key + server's existing rescue key available while the
  # persistent system's SSH ownership checks are being tightened.
  environment = {
    etc = {
      "ssh/authorized_keys.d/y0usaf".text = ''
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-desktop/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/y0usaf-server/user-ssh.pub)}
        ${lib.removeSuffix "\n" (builtins.readFile ../hosts/android-phone/user-ssh.pub)}
      '';
      sudoers.text = lib.mkAfter ''
        y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
      '';
      zshenv.text = ''
        # Intentionally minimal: exists so nixpkgs' compiled-in global zshenv
        # takes the `/etc/zshenv is readable` branch instead of trying to source
        # the NixOS-only /etc/set-environment, which finix does not generate.
      '';
    };
    shells = [
      "/run/current-system/sw/bin/zsh"
      "${pkgs.zsh}/bin/zsh"
    ];
    systemPackages = with pkgs; [
      curl
      iproute2
      iputils
      procps
      util-linux
      vim
      zsh
    ];
  };

  users.users.y0usaf = {
    isNormalUser = true;
    home = "/home/y0usaf";
    shell = "${pkgs.zsh}/bin/zsh";
    extraGroups = ["wheel"];
    # Password hash is supplied from the persistent secret store for local
    # console login only; sshd has PasswordAuthentication disabled. The file
    # must exist before rebuilding finix on bare metal.
    passwordFile = "/persist/secrets/password-hashes/y0usaf";
  };
}
