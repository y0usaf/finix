{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.shell.zellij.enable {
    user.shell.zellij.themeConfig =
      "\n// Neon theme configuration\n"
      + genLib.toKDL (import ../../../../lib/shell/zellij/theme.nix {})
      + "\ntheme \"neon\"\n";
  };
}
