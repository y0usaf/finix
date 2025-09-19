_: {
  config = {
    # Set up variables to be inherited from the user session
    environment.extraInit = ''
      # Inherit portal integration variables from active session
      # Only set if already present in environment (no hardcoded fallbacks)
      if [ -n "''${XDG_CURRENT_DESKTOP}" ]; then
        export XDG_CURRENT_DESKTOP
      fi
      if [ -n "''${WAYLAND_DISPLAY}" ]; then
        export WAYLAND_DISPLAY
      fi
    '';
  };
}
