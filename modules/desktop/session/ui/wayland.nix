{
  config,
  pkgs,
  lib,
  ...
}: let
  zshEnabled = lib.attrByPath ["user" "shell" "zsh" "enable"] false config;
  nushellEnabled = lib.attrByPath ["user" "shell" "nushell" "enable"] false config;
in {
  options.user.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };
  config = lib.mkIf config.user.ui.wayland.enable {
    environment.systemPackages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard-rs
      pkgs.hyprpicker
    ];
    bayt.users."${config.user.name}" = {
      files =
        lib.optionalAttrs zshEnabled {
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
        }
        // lib.optionalAttrs nushellEnabled {
          ".config/nushell/login.nu" = {
            text = lib.mkAfter ''
              $env.WLR_NO_HARDWARE_CURSORS = "1"
              $env.NIXOS_OZONE_WL = "1"
              $env.QT_QPA_PLATFORM = "wayland"
              $env.ELECTRON_OZONE_PLATFORM_HINT = "wayland"
              $env.XDG_SESSION_TYPE = "wayland"
              $env.GDK_BACKEND = "wayland"
              $env.SDL_VIDEODRIVER = "wayland,x11"
              $env.CLUTTER_BACKEND = "wayland"
              $env.GDK_DPI_SCALE = "${toString config.user.ui.gtk.scale}"
            '';
            clobber = true;
          };
        };
    };
  };
}
