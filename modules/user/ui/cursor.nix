{
  config,
  pkgs,
  lib,
  flakeInputs,
  system,
  ...
}: let
  username = config.user.name;
  hyprThemeName = "DeepinDarkV20-hypr";
  x11ThemeName = "DeepinDarkV20-x11";
  xcursorPackage = flakeInputs.deepin-dark-xcursor.packages.${system}.default;
  hyprcursorPackage = null;
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf config.user.ui.cursor.enable {
    environment.systemPackages =
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
              export XCURSOR_SIZE="${toString config.user.core.appearance.cursorSize}"
            ''
            + lib.optionalString (hyprcursorPackage != null) ''
              export HYPRCURSOR_THEME="${hyprThemeName}"
              export HYPRCURSOR_SIZE="${toString config.user.core.appearance.cursorSize}"
            '');
          clobber = true;
        };
        ".config/gtk-3.0/settings.ini" = {
          text = lib.mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${x11ThemeName}
            gtk-cursor-theme-size=${toString config.user.core.appearance.cursorSize}
          '';
          clobber = true;
        };
        ".config/gtk-4.0/settings.ini" = {
          text = lib.mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${x11ThemeName}
            gtk-cursor-theme-size=${toString config.user.core.appearance.cursorSize}
          '';
          clobber = true;
        };
      };
    };
  };
}
