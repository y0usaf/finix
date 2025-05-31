###############################################################################
# Hyprland AGS Integration Module
# Contains AGS-specific configuration and keybindings
###############################################################################
{
  config,
  lib,
  hostHome,
  ...
}: let
  cfg = config.cfg.ui.hyprland;
in {
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # AGS Autostart Configuration
    ###########################################################################
    wayland.windowManager.hyprland.extraConfig = lib.mkIf hostHome.cfg.ui.ags.enable ''
      exec-once = 'exec ags run'
    '';

    ###########################################################################
    # AGS Keybindings
    ###########################################################################
    wayland.windowManager.hyprland.settings = {
      # AGS-specific keybindings
      bind = lib.optionals hostHome.cfg.ui.ags.enable [
        "$mod, W, exec, ags request showStats"
        # Alt+Tab to toggle workspace indicators
        "$mod2, TAB, exec, ags request toggleWorkspaces"
      ];

      # Additional AGS bindings for show/hide functionality
      bindr = lib.mkIf hostHome.cfg.ui.ags.enable [
        "$mod, W, exec, ags request hideStats"
      ];
    };
  };
}
