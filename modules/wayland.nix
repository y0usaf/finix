{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = lib.mkIf (builtins.elem "wayland" profile.features) {
    programs.zsh = {
      envExtra = ''
        # Wayland environment variables
        export WLR_NO_HARDWARE_CURSORS=1
        export NIXOS_OZONE_WL=1
        export QT_QPA_PLATFORM=wayland
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
        export XDG_SESSION_TYPE=wayland
        export GDK_BACKEND=wayland,x11
        export SDL_VIDEODRIVER=wayland
        export CLUTTER_BACKEND=wayland
      '';
    };

    # Add Wayland-specific packages
    home.packages = with pkgs; [
      grim # Screenshot utility for Wayland
      slurp # Screen region selector tool
      wl-clipboard # Clipboard utility for Wayland
      hyprpicker # Color picker for Hyprland
    ];
  };
}
