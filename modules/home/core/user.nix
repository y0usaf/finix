{
  config,
  lib,
  ...
}: {
  options.home.core.user = {
    enable = lib.mkEnableOption "user configuration (packages and bookmarks)";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "List of additional user-specific packages";
    };
    bookmarks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "GTK bookmarks for file manager";
    };
  };
  config =
    lib.mkIf config.home.core.user.enable {
    };
}
