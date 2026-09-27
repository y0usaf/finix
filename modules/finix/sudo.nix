{
  config,
  pkgs,
  lib,
  flakeInputs,
  ...
}: {
  imports = [flakeInputs.finix.nixosModules.sudo];

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

    source = lib.mkForce (pkgs.runCommand "sudoers.in"
      {
        src = pkgs.writeText "sudoers.in" config.environment.etc."sudoers".text;
        preferLocalBuild = true;
      }
      "${pkgs.buildPackages.sudo}/sbin/visudo -f $src -c && cp $src $out");
  };

  security.wrappers = {
    sudo = {
      source = lib.getExe pkgs.sudo;
      owner = "root";
      group = "root";
      setuid = true;
      permissions = "u+rx,g+x,o+x";
    };
    sudoedit = {
      source = "${pkgs.sudo}/bin/sudoedit";
      owner = "root";
      group = "root";
      setuid = true;
      permissions = "u+rx,g+x,o+x";
    };
  };

  providers.privileges.backend = "sudo";
}
