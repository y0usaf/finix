###############################################################################
# User Configuration Module
# User-specific packages and settings
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.home.core.user;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
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

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # No packages or files needed - this is just option definitions
  };
}
