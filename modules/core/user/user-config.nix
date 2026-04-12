{
  config,
  lib,
  ...
}: {
  options = {
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Primary username for the system";
      };

      homeDirectory = lib.mkOption {
        type = lib.types.path;
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
  };
}
