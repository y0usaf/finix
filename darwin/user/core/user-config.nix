{
  lib,
  config,
  ...
}: {
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
      };

      configDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.config";
      };

      dataDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.local/share";
      };

      stateDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.local/state";
      };

      cacheDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/.cache";
      };

      nixosConfigDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/nixos";
      };

      tokensDirectory = lib.mkOption {
        type = lib.types.path;
        default = "${config.user.homeDirectory}/Tokens";
      };
    };
  };

  config = {
    user = {
      name = "y0usaf";
      homeDirectory = "/Users/${config.user.name}";
    };

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
  };
}
