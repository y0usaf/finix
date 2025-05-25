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
      exec-once = ags
    '';

    ###########################################################################
    # AGS Keybindings
    ###########################################################################
    wayland.windowManager.hyprland.settings = {
      # AGS-specific keybindings
      bind = lib.mkIf hostHome.cfg.ui.ags.enable [
        # Win+W to toggle system stats (like the old agsv1)
        "$mod, W, exec, ags -r 'toggleStats()'"
        
        # Alt+Tab to toggle workspace indicators
        "$mod2, TAB, exec, ags -r 'toggleWorkspaces()'"
      ];

      # Additional AGS bindings for show/hide functionality
      bindr = lib.mkIf hostHome.cfg.ui.ags.enable [
        # Release binding for Win+W to hide stats when key is released
        "$mod, W, exec, ags -r 'hideStats()'"
      ];
    };
  };
}