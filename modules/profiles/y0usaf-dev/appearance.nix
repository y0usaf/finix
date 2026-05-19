{
  pkgs,
  flakeInputs,
  ...
}: {
  user.appearance = {
    dpi = 189;
    termFontSize = 12;
    gtkFontSize = 23;
    xcursorSize = 18;
    opacity = 0.7;
    wallust.defaultTheme = "pantera";
  };

  user.ui.cursor.package = flakeInputs.cursors.packages."${pkgs.stdenv.hostPlatform.system}".deepin-dark;
}
