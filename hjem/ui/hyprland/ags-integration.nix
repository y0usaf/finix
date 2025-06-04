###############################################################################
# Hyprland AGS Integration Module (Hjem Version)
# Contains AGS-specific configuration and keybindings
###############################################################################
{
  config,
  lib,
  hostHome,
  ...
}: let
  cfg = config.cfg.hjome.ui.hyprland;
in {
  ###########################################################################
  # Internal Configuration Storage
  ###########################################################################
  options.cfg.hjome.ui.hyprland.agsIntegration = lib.mkOption {
    type = lib.types.attrs;
    internal = true;
    default = {};
    description = "Hyprland AGS integration configuration attributes";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    cfg.hjome.ui.hyprland.agsIntegration = {
      ###########################################################################
      # AGS Autostart Configuration
      ###########################################################################
      "exec-once" = lib.optionals hostHome.cfg.ui.ags.enable [
        "exec ags run"
      ];

      ###########################################################################
      # AGS Keybindings
      ###########################################################################
      bind = lib.optionals hostHome.cfg.ui.ags.enable [
        "$mod, W, exec, ags request showStats"
        # Alt+Tab to toggle workspace indicators
        "$mod2, TAB, exec, ags request toggleWorkspaces"
      ];

      # Additional AGS bindings for show/hide functionality
      bindr = lib.optionals hostHome.cfg.ui.ags.enable [
        "$mod, W, exec, ags request hideStats"
      ];
    };
  };
}