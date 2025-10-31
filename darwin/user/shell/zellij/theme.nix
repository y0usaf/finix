{genLib, ...}: let
  sharedTheme = import ../../../../lib/shared/shell/zellij/theme.nix {};
in {
  config.user.shell.zellij.themeConfig = genLib.toKDL sharedTheme;
}
