{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkAfter;
  x11ThemeName = "SSB-x11";
  cursorsPkgs = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}";
  hyprcursorPackage = cursorsPkgs."deepin-dark-hyprcursor";
  inherit (config) user;
  inherit (user) shell;
  inherit (user.appearance) cursorSize;
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf user.ui.cursor.enable {
    environment.systemPackages =
      [
        cursorsPkgs."ssb-xcursor"
      ]
      ++ lib.optionals (hyprcursorPackage != null) [
        hyprcursorPackage
      ];

    bayt.users."${user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
            clobber = true;
          };
          ".config/gtk-4.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = mkAfter (''
                export XCURSOR_THEME="${x11ThemeName}"
                export XCURSOR_SIZE="${toString cursorSize}"
              ''
              + lib.optionalString (hyprcursorPackage != null) ''
                export HYPRCURSOR_THEME="DeepinDarkV20-hypr"
                export HYPRCURSOR_SIZE="${toString cursorSize}"
              '');
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = mkAfter (''
                $env.XCURSOR_THEME = "${x11ThemeName}"
                $env.XCURSOR_SIZE = "${toString cursorSize}"
              ''
              + lib.optionalString (hyprcursorPackage != null) ''
                $env.HYPRCURSOR_THEME = "DeepinDarkV20-hypr"
                $env.HYPRCURSOR_SIZE = "${toString cursorSize}"
              '');
            clobber = true;
          };
        };
    };
  };
}
