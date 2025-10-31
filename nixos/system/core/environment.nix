_: {
  config = {
    environment.extraInit = ''
      if [ -n "''${XDG_CURRENT_DESKTOP}" ]; then
        export XDG_CURRENT_DESKTOP
      fi
      if [ -n "''${WAYLAND_DISPLAY}" ]; then
        export WAYLAND_DISPLAY
      fi
    '';
  };
}
