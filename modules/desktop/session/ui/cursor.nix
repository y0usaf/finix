{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkAfter;
  cursorsPkgs = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}";
  inherit (config) user;
  inherit (user) shell;
  inherit (user.appearance) cursorSize cursorColor cursorTheme;
  colorCap = (lib.toUpper (builtins.substring 0 1 cursorColor)) + (builtins.substring 1 (-1) cursorColor);

  theme =
    if (cursorTheme == "popucom")
    then {
      x11ThemeName = "Popucom-${colorCap}-x11";
      hyprThemeName = "Popucom-${colorCap}-hypr";
      xcursorPackage = cursorsPkgs."popucom-${cursorColor}-xcursor";
      hyprcursorPackage = cursorsPkgs."popucom-${cursorColor}-hyprcursor";
    }
    else {
      x11ThemeName = "DeepinDarkV20-x11";
      hyprThemeName = "DeepinDarkV20-hypr";
      xcursorPackage = cursorsPkgs.deepin-dark-xcursor;
      hyprcursorPackage = cursorsPkgs.deepin-dark-hyprcursor;
    };
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
      [theme.xcursorPackage]
      ++ lib.optional (theme ? hyprcursorPackage) theme.hyprcursorPackage;

    bayt.users."${user.name}" = {
      files =
        {
          ".config/gtk-3.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${theme.x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
          };
          ".config/gtk-4.0/settings.ini" = {
            text = mkAfter ''
              [Settings]
              gtk-cursor-theme-name=${theme.x11ThemeName}
              gtk-cursor-theme-size=${toString cursorSize}
            '';
          };
        }
        // lib.optionalAttrs shell.zsh.enable {
          ".config/zsh/.zprofile" = {
            text = mkAfter (''
                export XCURSOR_THEME="${theme.x11ThemeName}"
                export XCURSOR_SIZE="${toString cursorSize}"
              ''
              + lib.optionalString (theme ? hyprThemeName) ''
                export HYPRCURSOR_THEME="${theme.hyprThemeName}"
                export HYPRCURSOR_SIZE="${toString cursorSize}"
              '');
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = mkAfter (''
                $env.XCURSOR_THEME = "${theme.x11ThemeName}"
                $env.XCURSOR_SIZE = "${toString cursorSize}"
              ''
              + lib.optionalString (theme ? hyprThemeName) ''
                $env.HYPRCURSOR_THEME = "${theme.hyprThemeName}"
                $env.HYPRCURSOR_SIZE = "${toString cursorSize}"
              '');
          };
        };
    };
  };
}
