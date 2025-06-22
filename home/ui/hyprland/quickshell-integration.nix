###############################################################################
# Hyprland Quickshell Integration Module (Maid Version)
# Contains Quickshell-specific configuration and keybindings
###############################################################################
{
  config,
  lib,
  ...
}: let
  # Safely check if Quickshell is enabled
  quickshellEnabled = config.home.ui.quickshell.enable or false;
in
  ###########################################################################
  # Quickshell Integration Configuration
  ###########################################################################
  {
    ###########################################################################
    # Quickshell Autostart Configuration
    ###########################################################################
    "exec-once" = lib.optionals quickshellEnabled [
      "exec quickshell"
    ];

    ###########################################################################
    # Quickshell Keybindings
    ###########################################################################
    bind = lib.optionals quickshellEnabled [
      # Hold Super for 500ms to show workspace overview
      "$mod, $mod_L, exec, quickshell-ipc toggle-overview"
      # Alternative: Manual toggle with Super+O
      "$mod, O, exec, quickshell-ipc toggle-overview"
    ];
  }