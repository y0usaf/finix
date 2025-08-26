{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.wayland;
  gtkCfg = config.home.ui.gtk;
in {
  options.home.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        grim
        slurp
        wl-clipboard
        hyprpicker
      ];
      files = {
        ".config/zsh/.zshenv" = {
          text = lib.mkAfter ''
            export WLR_NO_HARDWARE_CURSORS=1
            export NIXOS_OZONE_WL=1
            export QT_QPA_PLATFORM=wayland
            export ELECTRON_OZONE_PLATFORM_HINT=wayland
            export XDG_SESSION_TYPE=wayland
            export GDK_BACKEND=wayland,x11
            export SDL_VIDEODRIVER=wayland
            export CLUTTER_BACKEND=wayland
            export GDK_DPI_SCALE=${toString gtkCfg.scale}
          '';
          clobber = true;
        };
      };
    };
  };
}
