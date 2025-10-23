{
  config,
  lib,
  flakeInputs,
  system,
  ...
}: let
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

    hjem.users.${config.user.name} = {
      files =
        {
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
        }
        // lib.optionalAttrs config.user.shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = lib.mkAfter (''
                export XCURSOR_THEME="${x11ThemeName}"
                export XCURSOR_SIZE="${toString config.user.core.appearance.cursorSize}"
              ''
              + lib.optionalString (hyprcursorPackage != null) ''
                export HYPRCURSOR_THEME="DeepinDarkV20-hypr"
                export HYPRCURSOR_SIZE="${toString config.user.core.appearance.cursorSize}"
              '');
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.nushell.enable {
          ".config/nushell/env.nu" = {
            text = lib.mkAfter ''
              $env.XCURSOR_THEME = "${x11ThemeName}"
              $env.XCURSOR_SIZE = "${toString config.user.core.appearance.cursorSize}"
            '';
            clobber = true;
          };
        };
    };
  };
}
