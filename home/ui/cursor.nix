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
  cfg = config.home.ui.cursor;
  username = "y0usaf";
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";

  # Get the packages directly from flake outputs
  hyprcursorPackage = inputs.deepin-dark-hyprcursor.packages.${pkgs.system}.default;
  xcursorPackage = inputs.deepin-dark-xcursor.packages.${pkgs.system}.default;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.cursor = {
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
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        hyprcursorPackage
        xcursorPackage
      ];

      file.home = {
        ".profile".text = lib.mkAfter ''
          export HYPRCURSOR_THEME="${hyprThemeName}"
          export HYPRCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
          export XCURSOR_THEME="${x11ThemeName}"
          export XCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
        '';
      };

      file.xdg_config = {
        "gtk-3.0/settings.ini".text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${x11ThemeName}
          gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
        '';
        "gtk-4.0/settings.ini".text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${x11ThemeName}
          gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
        '';
      };
    };
  };
}
