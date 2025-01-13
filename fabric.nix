#===============================================================================
#
#                     Fabric Configuration
#
# Description:
#     Configuration file for Fabric, managing:
#     - Workspace management
#     - Notification system
#     - Configuration files
#     - Required dependencies
#
# Author: y0usaf
# Last Modified: 2025
#
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  # Install only gobject-introspection as system dependency
  home.packages = with pkgs; [
    gobject-introspection
  ];

  # Set up virtual environment and install dependencies
  home.activation.fabricSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/fabric

    # Create virtual environment if it doesn't exist
    if [ ! -d "$HOME/.config/fabric/venv" ]; then
      ${pkgs.uv}/bin/uv venv "$HOME/.config/fabric/venv"

      # Install required packages
      source "$HOME/.config/fabric/venv/bin/activate"
      ${pkgs.uv}/bin/uv pip install \
        pygobject \
        dbus-python
    fi
  '';

  # Workspace toggle script
  xdg.configFile."fabric/toggle_workspaces.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      # Toggle between workspace configurations
      if [ -f /tmp/workspace_mode ]; then
          rm /tmp/workspace_mode
          hyprctl keyword monitor "DP-4,5120x1440@239.76,0x0,1"
          hyprctl keyword monitor "HDMI-A-2,5120x1440@239.76,0x1440,1"
      else
          touch /tmp/workspace_mode
          hyprctl keyword monitor "DP-4,5120x1440@239.76,0x0,1"
          hyprctl keyword monitor "HDMI-A-2,disable"
      fi
    '';
  };

  # Update notifications script to use venv Python
  xdg.configFile."fabric/notifications.py" = {
    executable = true;
    text = ''
      #!${config.home.homeDirectory}/.config/fabric/venv/bin/python3

      import gi
      import dbus
      from dbus.mainloop.glib import DBusGMainLoop

      gi.require_version('Gtk', '3.0')
      from gi.repository import GLib

      def notifications_handler(*args):
          # Handle notification events here
          pass

      DBusGMainLoop(set_as_default=True)
      bus = dbus.SessionBus()
      bus.add_match_string_non_blocking(
          "type='method_call',interface='org.freedesktop.Notifications'"
      )
      bus.add_message_filter(notifications_handler)

      mainloop = GLib.MainLoop()
      mainloop.run()
    '';
  };

  # Update Hyprland configuration to use Fabric
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "python ~/.config/fabric/notifications.py"
      "~/.config/fabric/toggle_workspaces.sh"
    ];

    bind = [
      "$mod, W, exec, ~/.config/fabric/toggle_workspaces.sh"
    ];

    layerrule = [
      "blur, fabric"
    ];
  };
}
