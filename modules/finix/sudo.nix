{
  config,
  pkgs,
  lib,
  ...
}: {
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

      (lib.concatMapStringsSep "\n" (
          rule: let
            runAs =
              if rule.runAs == "*"
              then "ALL"
              else rule.runAs;
            opts = lib.optionalString (!rule.requirePassword) "NOPASSWD:";
          in ''
            ${lib.concatMapStringsSep "\n" (
                user: "${user} ALL = (${runAs}) ${opts} ${rule.command} ${toString rule.args}"
              )
              rule.users}
            ${lib.concatMapStringsSep "\n" (
                group: "%${group} ALL = (${runAs}) ${opts} ${rule.command} ${toString rule.args}"
              )
              rule.groups}
          ''
        )
        config.providers.privileges.rules)
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
      source = lib.getExe pkgs.sudo;
      inherit
        owner
        group
        setuid
        permissions
        ;
    };
    sudoedit = {
      source = "${pkgs.sudo}/bin/sudoedit";
      inherit
        owner
        group
        setuid
        permissions
        ;
    };
  };

  providers.privileges.command = "/run/wrappers/bin/sudo";
}
