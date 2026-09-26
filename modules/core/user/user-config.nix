{
  config,
  lib,
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
}
