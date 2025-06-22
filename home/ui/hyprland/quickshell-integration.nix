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
    # Quickshell Keybindings (Process Signal-based)  
    ###########################################################################
    bind = lib.optionals quickshellEnabled [
      # Manual toggle workspace overview with Super+O
      "$mod, O, exec, pkill -USR1 quickshell"
      # Alternative: Super+Tab for quick toggle
      "$mod, TAB, exec, pkill -USR1 quickshell"
    ];
    
    # Hold mod key bindings for overview
    bindr = lib.optionals quickshellEnabled [
      # Show overview while holding Super key (left)
      "$mod, $mod_L, exec, pkill -USR2 quickshell"
      # Show overview while holding Super key (right)  
      "$mod, $mod_R, exec, pkill -USR2 quickshell"
    ];
  }