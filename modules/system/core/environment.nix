_: {
  config = {
    # Set up variables to be inherited from the user session
    environment.extraInit = ''
      # Inherit portal integration variables from active session
      export XDG_CURRENT_DESKTOP=''${XDG_CURRENT_DESKTOP:-"niri"}
      export WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-"wayland-1"}
    '';
  };
}
