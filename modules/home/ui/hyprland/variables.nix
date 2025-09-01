{
  lib,
  config,
  ...
}: let
  cfg = config.home.ui.hyprland;
  inherit (config.home.core) defaults;
  generators = import ../../../../lib/generators/toHyprconf.nix lib;

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
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkBefore (generators.toHyprconf {
        attrs = variablesConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
