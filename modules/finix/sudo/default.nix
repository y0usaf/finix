{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.sudo;
in
{
  imports = [
    ./providers.privileges.nix
  ];

  options.programs.sudo = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable [sudo](${pkgs.sudo.meta.homepage}).
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.sudo;
      defaultText = lib.literalExpression "pkgs.sudo";
      description = ''
        The package to use for `sudo`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # NOTE (local override, mirrors ~/finix fix for upstream finix bug): the
    # stock finix-community/finix sudo module at
    #   modules/programs/sudo/default.nix
    # also sets `environment.systemPackages = [ cfg.package ];`. That puts
    # the RAW, mode-0555 (no setuid) sudo binary into /run/current-system/sw/bin,
    # which SHADOWS the correct setuid wrapper (setuid=true) that this module
    # installs at /run/wrappers/bin/sudo — so PATH resolves the non-setuid raw
    # binary and every `sudo` invocation fails with
    #   "must be owned by uid 0 and have the setuid bit set".
    # Mainline NixOS's programs.sudo.enable installs ONLY the setuid wrapper.
    # We therefore do NOT add cfg.package to environment.systemPackages; the
    # wrapper stays the only `sudo` on PATH. The real binary is still reachable
    # and exec'd through the wrapper (security.wrappers below).
    security.pam.services.sudo.text = ''
      # Account management.
      account required pam_unix.so # unix (order 10900)

      # Authentication management.
      auth sufficient pam_unix.so likeauth try_first_pass # unix (order 11500)
      auth required pam_deny.so # deny (order 12300)

      # Password management.
      password sufficient pam_unix.so nullok yescrypt # unix (order 10200)

      # Session management.
      session required pam_env.so conffile=/etc/security/pam_env.conf readenv=0 # env (order 10100)
      session required pam_unix.so # unix (order 10200)
      session required pam_limits.so
    '';

    environment.etc.sudoers = {
      mode = "0440";
      text = lib.mkMerge [
        (lib.mkBefore ''
          # Don't edit this file. Set the NixOS options ‘security.sudo.configFile’
          # or ‘security.sudo.extraRules’ instead.
        '')

        (lib.mkAfter ''
          # extraConfig
          Defaults:root,%wheel timestamp_timeout=60

          # Keep terminfo database for root and %wheel.
          Defaults:root,%wheel env_keep+=TERMINFO_DIRS
          Defaults:root,%wheel env_keep+=TERMINFO

          # keep NIXOS_NO_CHECK for `nixos-rebuild switch`
          Defaults env_keep+=NIXOS_NO_CHECK
        '')

        ''
          root    ALL=(ALL:ALL)    SETENV: ALL
          %wheel  ALL=(ALL:ALL)    SETENV: ALL
        ''
      ];

      source =
        let
          value =
            pkgs.runCommand "sudoers.in"
              {
                src = pkgs.writeText "sudoers.in" config.environment.etc."sudoers".text;
                preferLocalBuild = true;
              }
              # Make sure that the sudoers file is syntactically valid.
              "${pkgs.buildPackages.sudo}/sbin/visudo -f $src -c && cp $src $out";
        in
        lib.mkForce value;
    };

    security.wrappers =
      let
        owner = "root";
        group = "root";
        setuid = true;
        permissions = "u+rx,g+x,o+x";
      in
      {
        sudo = {
          source = lib.getExe cfg.package;
          inherit
            owner
            group
            setuid
            permissions
            ;
        };
        sudoedit = {
          source = "${cfg.package}/bin/sudoedit";
          inherit
            owner
            group
            setuid
            permissions
            ;
        };
      };

    # this module supplies an implementation for `providers.privileges`
    providers.privileges.backend = lib.mkDefault "sudo";
  };
}
