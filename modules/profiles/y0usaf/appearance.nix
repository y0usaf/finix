{
  pkgs,
  flakeInputs,
  ...
}: {
  user.appearance = {
    dpi = 109;
    termFontSize = 16;
    gtkFontSize = 12;
    xcursorSize = 18;
    hyprcursorSize = 36;
    opacity = 0.7;
    wallust.defaultTheme = "pantera";
  };

  user.ui.cursor.package = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}".deepin-dark;
}
