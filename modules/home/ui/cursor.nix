{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.cursor;
  username = config.user.name;
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";
  xcursorPackage = pkgs.deepin-dark-xcursor;
  hyprcursorPackage = null;
in {
  options.home.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        xcursorPackage
      ]
      ++ lib.optionals (hyprcursorPackage != null) [
        hyprcursorPackage
      ];

    hjem.users.${username} = {
      files = {
        ".config/zsh/.zprofile" = {
          text = lib.mkAfter (''
              export XCURSOR_THEME="${x11ThemeName}"
              export XCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
            ''
            + lib.optionalString (hyprcursorPackage != null) ''
              export HYPRCURSOR_THEME="${hyprThemeName}"
              export HYPRCURSOR_SIZE="${toString config.home.core.appearance.cursorSize}"
            '');
          clobber = true;
        };
        ".config/gtk-3.0/settings.ini" = {
          text = lib.mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${x11ThemeName}
            gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
          '';
          clobber = true;
        };
        ".config/gtk-4.0/settings.ini" = {
          text = lib.mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${x11ThemeName}
            gtk-cursor-theme-size=${toString config.home.core.appearance.cursorSize}
          '';
          clobber = true;
        };
      };
    };
  };
}
