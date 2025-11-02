{genLib, ...}: let
  sharedTheme = import ../../../../lib/shell/zellij/theme.nix {};
in {
  config.user.shell.zellij.themeConfig = genLib.toKDL sharedTheme;
}
