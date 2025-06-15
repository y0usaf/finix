###############################################################################
# Wallust Color Generation (Maid Version)
# Wallpaper-based color scheme generation for system-wide theming
# - Wallpaper-based color scheme generation
# - System-wide theme integration
# - Auto-generation on wallpaper change
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.home.ui.wallust;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      wallust
    ];
  };
}
