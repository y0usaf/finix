###############################################################################
# Hyprland AGS Integration Module (Hjem Version)
# Contains AGS-specific configuration and keybindings
###############################################################################
{
  config,
  lib,
  cfg,
  ...
}: let
  # Safely check if AGS is enabled
  agsEnabled = config.cfg.home.ui.ags.enable or false;
in
  ###########################################################################
  # AGS Integration Configuration
  ###########################################################################
  {
    ###########################################################################
    # AGS Autostart Configuration
    ###########################################################################
    "exec-once" = lib.optionals agsEnabled [
      "exec ags run"
    ];

    ###########################################################################
    # AGS Keybindings
    ###########################################################################
    bind = lib.optionals agsEnabled [
      "$mod, W, exec, ags request showStats"
      # Alt+Tab to toggle workspace indicators
      "$mod2, TAB, exec, ags request toggleWorkspaces"
    ];

    # Additional AGS bindings for show/hide functionality
    bindr = lib.optionals agsEnabled [
      "$mod, W, exec, ags request hideStats"
    ];
  }
