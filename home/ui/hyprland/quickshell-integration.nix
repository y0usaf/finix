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
      # Toggle workspace overview with Super+Tab
      "$mod, TAB, exec, quickshell ipc call overview toggle"
      # Show overview when pressing Super key
      "Super_L, exec, quickshell ipc call overview display"
    ];
    
    # Release key bindings for overview
    bindr = lib.optionals quickshellEnabled [
      # Hide overview when releasing Super key
      "Super_L, exec, quickshell ipc call overview dismiss"
    ];
  }
