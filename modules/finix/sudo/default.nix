{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.programs.sudo;
in {
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
    security.pam.services.sudo.text = ''
      account required pam_unix.so # unix (order 10900)

      auth sufficient pam_unix.so likeauth try_first_pass # unix (order 11500)
      auth required pam_deny.so # deny (order 12300)

      password sufficient pam_unix.so nullok yescrypt # unix (order 10200)

      session required pam_env.so conffile=/etc/security/pam_env.conf readenv=0 # env (order 10100)
      session required pam_unix.so # unix (order 10200)
      session required pam_limits.so
    '';

    environment.etc.sudoers = {
      mode = "0440";
      text = lib.mkMerge [
        (lib.mkBefore ''
          '')

        (lib.mkAfter ''
          Defaults:root,%wheel timestamp_timeout=60

          Defaults:root,%wheel env_keep+=TERMINFO_DIRS
          Defaults:root,%wheel env_keep+=TERMINFO

          Defaults env_keep+=NIXOS_NO_CHECK
        '')

        ''
          root    ALL=(ALL:ALL)    SETENV: ALL
          %wheel  ALL=(ALL:ALL)    SETENV: ALL
        ''
      ];

      source = let
        value =
          pkgs.runCommand "sudoers.in"
          {
            src = pkgs.writeText "sudoers.in" config.environment.etc."sudoers".text;
            preferLocalBuild = true;
          }
          "${pkgs.buildPackages.sudo}/sbin/visudo -f $src -c && cp $src $out";
      in
        lib.mkForce value;
    };

    security.wrappers = let
      owner = "root";
      group = "root";
      setuid = true;
      permissions = "u+rx,g+x,o+x";
    in {
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

    providers.privileges.backend = lib.mkDefault "sudo";
  };
}
