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
  inputs,
  ...
}: {
  # Install required system dependencies
  home.packages = with pkgs; [
    gobject-introspection
    gtk3
  ];

  # Set up virtual environment and install dependencies
  home.activation.fabricSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/fabric/cache

    # Create virtual environment if it doesn't exist
    if [ ! -d "$HOME/.config/fabric/venv" ]; then
      UV_CACHE_DIR="$HOME/.config/fabric/cache" \
      UV_SYSTEM_PYTHON="${pkgs.python311}/bin/python3" \
      UV_NO_BINARY=1 \
      ${inputs.uv2nix.packages.${pkgs.system}.uv-bin}/bin/uv venv "$HOME/.config/fabric/venv"

      # Install required packages
      source "$HOME/.config/fabric/venv/bin/activate"
      export GI_TYPELIB_PATH="${pkgs.gtk3}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0"
      UV_CACHE_DIR="$HOME/.config/fabric/cache" \
      UV_NO_BINARY=1 \
      ${inputs.uv2nix.packages.${pkgs.system}.uv-bin}/bin/uv pip install \
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

  # Notifications script
  xdg.configFile."fabric/notifications.py" = {
    executable = true;
    text = ''
      #!${config.home.homeDirectory}/.config/fabric/venv/bin/python

      import os
      os.environ['GI_TYPELIB_PATH'] = "${pkgs.gtk3}/lib/girepository-1.0:" + \
                                     "${pkgs.gobject-introspection}/lib/girepository-1.0"

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

  # Hyprland configuration
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "GI_TYPELIB_PATH=${pkgs.gtk3}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0 $HOME/.config/fabric/venv/bin/python $HOME/.config/fabric/notifications.py"
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
