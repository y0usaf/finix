{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  xcursorSize = 18;
  cursorPackage = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}".deepin-dark;
in {
  environment = {
    systemPackages = cursorPackage.cursorPackages or [cursorPackage];
    variables = cursorPackage.mkCursorSessionVariables {
      inherit xcursorSize;
      inherit (config.user.appearance) hyprcursorSize;
    };
  };

  manzil.users."${config.user.name}" = {
    files = {
      ".config/gtk-3.0/settings.ini" = {
        text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
          gtk-cursor-theme-size=${toString xcursorSize}
        '';
      };
      ".config/gtk-4.0/settings.ini" = {
        text = lib.mkAfter ''
          [Settings]
          gtk-cursor-theme-name=${cursorPackage.xcursorThemeName}
          gtk-cursor-theme-size=${toString xcursorSize}
        '';
      };
    };
  };
}
