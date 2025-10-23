{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };
  config = lib.mkIf config.user.ui.wayland.enable {
    environment.systemPackages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.hyprpicker
    ];
    usr = {
      files = lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter ''
            export WLR_NO_HARDWARE_CURSORS=1
            export NIXOS_OZONE_WL=1
            export QT_QPA_PLATFORM=wayland
            export ELECTRON_OZONE_PLATFORM_HINT=wayland
            export XDG_SESSION_TYPE=wayland
            export GDK_BACKEND=wayland
            export SDL_VIDEODRIVER=wayland,x11
            export CLUTTER_BACKEND=wayland
            export GDK_DPI_SCALE=${toString config.user.ui.gtk.scale}
          '';
          clobber = true;
        };
      };
    };
  };
}
