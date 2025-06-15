###############################################################################
# Cursor Configuration
# Configures cursor themes for X11 and Wayland/Hyprland
# - Custom DeepinDarkV20 cursor themes
# - Separate X11 and Hyprland cursor packages
# - System-wide cursor configuration
###############################################################################
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  cfg = config.cfg.home.ui.cursor;
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";

  # Get the packages directly from flake outputs
  hyprcursorPackage = inputs.deepin-dark-hyprcursor.packages.${pkgs.system}.default;
  xcursorPackage = inputs.deepin-dark-xcursor.packages.${pkgs.system}.default;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Package Installation
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      hyprcursorPackage
      xcursorPackage
    ];

    ###########################################################################
    # Configuration Files
    ###########################################################################
    users.users.y0usaf.maid.file.home = {
      ".profile".text = lib.mkAfter ''
        export HYPRCURSOR_THEME="${hyprThemeName}"
        export HYPRCURSOR_SIZE="${toString config.cfg.home.core.appearance.cursorSize}"
        export XCURSOR_THEME="${x11ThemeName}"
        export XCURSOR_SIZE="${toString config.cfg.home.core.appearance.cursorSize}"
      '';
      ".Xresources".text = lib.mkAfter ''
        Xcursor.theme: ${x11ThemeName}
        Xcursor.size: ${toString config.cfg.home.core.appearance.cursorSize}
      '';
    };

    users.users.y0usaf.maid.file.xdg_config = {
      "gtk-3.0/settings.ini".text = lib.mkAfter ''
        [Settings]
        gtk-cursor-theme-name=${x11ThemeName}
        gtk-cursor-theme-size=${toString config.cfg.home.core.appearance.cursorSize}
      '';
      "gtk-4.0/settings.ini".text = lib.mkAfter ''
        [Settings]
        gtk-cursor-theme-name=${x11ThemeName}
        gtk-cursor-theme-size=${toString config.cfg.home.core.appearance.cursorSize}
      '';
    };
  };
}