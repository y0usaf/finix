{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkAfter;
  inherit (config) user;
  inherit (user.appearance) hyprcursorSize xcursorSize;
  inherit (user.ui) cursor;
  cursorPackage = cursor.package;
  cursorSessionVariables = cursorPackage.mkCursorSessionVariables {
    inherit xcursorSize hyprcursorSize;
  };
in {
  options.user.ui.cursor = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable cursor theme configuration";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}".deepin-dark;
      description = ''
        Combined cursor theme package. The package is expected to expose cursor
        metadata through passthru, including xcursorThemeName and
        mkCursorSessionVariables.
      '';
    };
  };

  config = lib.mkIf cursor.enable {
    environment = {
      systemPackages = cursorPackage.cursorPackages or [cursorPackage];
      # Single owner for XCURSOR_*/HYPRCURSOR_* (gtk/config.nix owns GDK_DPI_SCALE).
      variables = cursorSessionVariables;
    };

    manzil.users."${user.name}" = {
      files = {
        ".config/gtk-3.0/settings.ini" = {
          text = mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
            gtk-cursor-theme-size=${toString xcursorSize}
          '';
        };
        ".config/gtk-4.0/settings.ini" = {
          text = mkAfter ''
            [Settings]
            gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
            gtk-cursor-theme-size=${toString xcursorSize}
          '';
        };
      };
    };
  };
}
