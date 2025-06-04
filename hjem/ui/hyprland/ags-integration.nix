###############################################################################
# Hyprland AGS Integration Module (Hjem Version)
# Contains AGS-specific configuration and keybindings
###############################################################################
{
  config,
  lib,
  hostHome,
  cfg,
  ...
}:
###########################################################################
# AGS Integration Configuration
###########################################################################
{
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
}