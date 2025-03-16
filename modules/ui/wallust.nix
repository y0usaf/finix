###############################################################################
# Wallust Color Generation
# Wallpaper-based color scheme generation for system-wide theming
# - 🖼️ Wallpaper-based color scheme generation
# - 🎯 System-wide theme integration
# - 🔄 Auto-generation on wallpaper change
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  inputs,
  ...
}: let
  cfg = config.modules.ui.wallust;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      wallust
      #inputs.hyprpaper.packages.${pkgs.system}.default
    ];
  };
}
