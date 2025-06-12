###############################################################################
# Wallust Color Generation (Hjem Version)
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
  cfg = config.cfg.hjome.ui.wallust;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      wallust
    ];
  };
}
