#===============================================================================
#                    🎨 Wallust Color Generation 🎨
#===============================================================================
# 🖼️ Wallpaper-based color scheme generation
# 🎯 System-wide theme integration
# 🔄 Auto-generation on wallpaper change
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "wallust" profile.features) {
    # Install wallust package
    home.packages = with pkgs; [
      wallust
      hyprpaper
    ];
  };
}
