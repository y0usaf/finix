{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) ui;
in {
  options.user.ui.wayland = {
    enable = lib.mkEnableOption "Wayland configuration";
  };
  config = lib.mkIf ui.wayland.enable {
    environment = {
      systemPackages = [
        pkgs.grim
        pkgs.slurp
        pkgs.wl-clipboard-rs
        pkgs.hyprpicker
      ];
      # Single owner for the Wayland env surface. /etc/profile.d exports these
      # for login shells, so the compositor and everything it spawns inherit
      # them — no per-shell rc duplication. MOZ_* live here rather than in the
      # browser modules: firefox.nix and librewolf.nix both set the same two
      # keys, which collides on merge, and "enable Wayland" is a Wayland fact.
      variables = {
        WLR_NO_HARDWARE_CURSORS = "1";
        NIXOS_OZONE_WL = "1";
        QT_QPA_PLATFORM = "wayland";
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
        XDG_SESSION_TYPE = "wayland";
        GDK_BACKEND = "wayland";
        SDL_VIDEODRIVER = "wayland,x11";
        CLUTTER_BACKEND = "wayland";
        MOZ_ENABLE_WAYLAND = "1";
        MOZ_USE_XINPUT2 = "1";
      };
    };
  };
}
