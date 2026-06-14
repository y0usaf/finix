{
  config,
  lib,
  pkgs,
  ...
}: {
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "y0usaf";
        description = "Primary username for the system";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
        default = "/home/${config.user.name}";
        description = "Home directory path for the user";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = config.user.name != "";
        message = "user.name must be set to a non-empty string";
      }
      {
        assertion = lib.hasPrefix "/" (toString config.user.homeDirectory);
        message = "user.homeDirectory must be an absolute path";
      }
    ];

    users.users."${config.user.name}" = {
      isNormalUser = true;
      shell = pkgs.nushell;
      home = toString config.user.homeDirectory;
      ignoreShellProgramCheck = true;
      extraGroups = ["wheel" "networkmanager" "docker"];
    };

    security.sudo.extraRules = [
      {
        users = [config.user.name];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
