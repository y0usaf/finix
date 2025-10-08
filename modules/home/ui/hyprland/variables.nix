{
  lib,
  config,
  genLib,
  ...
}: let
  inherit (config.home.core) defaults;

  variablesConfig = {
    "$mod" = "ALT";
    "$mod2" = "SUPER";
    "$term" = defaults.terminal;
    "$filemanager" = defaults.fileManager;
    "$browser" = defaults.browser;
    "$discord" = defaults.discord;
    "$launcher" = defaults.launcher;
    "$ide" = defaults.ide;
    "$notepad" = "${defaults.terminal} -e ${defaults.editor}";
    "$obs" = "obs";
  };
in {
  config = lib.mkIf config.home.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkBefore (genLib.toHyprconf {
        attrs = variablesConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
