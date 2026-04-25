{
  config,
  lib,
  ...
}: let
  inherit (config.user) appearance;
  inherit (appearance) cursorColor cursorSize;
in {
  config = lib.mkIf config.user.ui.sway.enable {
    programs.sway.extraSessionCommands = lib.mkAfter ''
      export XDG_CURRENT_DESKTOP=sway
      export XDG_SESSION_DESKTOP=sway
      export XDG_SESSION_TYPE=wayland
      export NIXOS_OZONE_WL=1
      export QT_QPA_PLATFORM=wayland
      export ELECTRON_OZONE_PLATFORM_HINT=wayland
      export GDK_BACKEND=wayland
      export SDL_VIDEODRIVER=wayland,x11
      export CLUTTER_BACKEND=wayland
      export GDK_DPI_SCALE=${toString config.user.ui.gtk.scale}
      export XCURSOR_THEME=Popucom-${(lib.toUpper (builtins.substring 0 1 cursorColor)) + (builtins.substring 1 (-1) cursorColor)}-x11
      export XCURSOR_SIZE=${toString cursorSize}
    '';
  };
}
