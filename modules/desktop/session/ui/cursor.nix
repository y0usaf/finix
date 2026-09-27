{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  inherit (lib) mkAfter;
  inherit (config) user;
  inherit (user.appearance) hyprcursorSize;
  xcursorSize = 18;
  cursorPackage = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}".deepin-dark;
  cursorSessionVariables = cursorPackage.mkCursorSessionVariables {
    inherit xcursorSize hyprcursorSize;
  };
in {
  environment = {
    systemPackages = cursorPackage.cursorPackages or [cursorPackage];
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
}
