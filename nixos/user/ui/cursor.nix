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
  inherit (user.appearance) cursorSize cursorColor;
  colorCap = let
    first = builtins.substring 0 1 cursorColor;
    rest = builtins.substring 1 (-1) cursorColor;
  in (lib.toUpper first) + rest;
  x11ThemeName = "Popucom-${colorCap}-x11";
  hyprThemeName = "Popucom-${colorCap}-hypr";
  xcursorPackage = cursorsPkgs."popucom-${cursorColor}-xcursor";
  hyprcursorPackage = cursorsPkgs."popucom-${cursorColor}-hyprcursor";
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };
  };
  config = lib.mkIf user.ui.cursor.enable {
    environment.systemPackages = [
      xcursorPackage
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
            text = mkAfter ''
              export XCURSOR_THEME="${x11ThemeName}"
              export XCURSOR_SIZE="${toString cursorSize}"
              export HYPRCURSOR_THEME="${hyprThemeName}"
              export HYPRCURSOR_SIZE="${toString cursorSize}"
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs shell.nushell.enable {
          ".config/nushell/login.nu" = {
            text = mkAfter ''
              $env.XCURSOR_THEME = "${x11ThemeName}"
              $env.XCURSOR_SIZE = "${toString cursorSize}"
              $env.HYPRCURSOR_THEME = "${hyprThemeName}"
              $env.HYPRCURSOR_SIZE = "${toString cursorSize}"
            '';
            clobber = true;
          };
        };
    };
  };
}
