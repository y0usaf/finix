{lib, ...}: {
  user.appearance = {
    gtkFontSize = lib.mkDefault 12;
    xcursorSize = lib.mkDefault 18;
    opacity = lib.mkDefault 0.7;
    wallust.defaultTheme = lib.mkDefault "pantera";
  };
}
