{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.cursor;
  username = "y0usaf";
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";
  hyprcursorPackage = pkgs.phinger-cursors; # Use standard cursor for npins compatibility
  xcursorPackage = pkgs.phinger-cursors;
in {
  options.home.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        hyprcursorPackage
        xcursorPackage
      ];
      file.home = {
        ".profile".text = lib.mkAfter ''
          export HYPRCURSOR_THEME="${hyprThemeName}"
          export HYPRCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
          export XCURSOR_THEME="${x11ThemeName}"
          export XCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
        '';
      };
      file.xdg_config = {
        "gtk-3.0/settings.ini".text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${x11ThemeName}
          gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
        '';
        "gtk-4.0/settings.ini".text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${x11ThemeName}
          gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
        '';
      };
    };
  };
}
