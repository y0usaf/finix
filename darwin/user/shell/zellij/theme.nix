{genLib, ...}: {
  config.user.shell.zellij.themeConfig = genLib.toKDL (import ../../../../lib/shell/zellij/theme.nix {});
}
