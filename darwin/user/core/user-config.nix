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
