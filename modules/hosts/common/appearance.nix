{lib, ...}: {
  user.appearance = {
    xcursorSize = lib.mkDefault 18;
    opacity = lib.mkDefault 0.7;
    wallust.defaultTheme = lib.mkDefault "pantera";
  };
}
