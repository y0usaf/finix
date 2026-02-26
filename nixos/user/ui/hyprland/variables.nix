{
  lib,
  config,
  genLib,
  ...
}: let
  variablesConfig = {
    "$mod" = "ALT";
    "$mod2" = "SUPER";
    "$term" = config.user.defaults.terminal;
    "$filemanager" = config.user.defaults.fileManager;
    "$browser" = config.user.defaults.browser;
    "$discord" = config.user.defaults.discord;
    "$launcher" = config.user.defaults.launcher;
    "$ide" = config.user.defaults.ide;
    "$notepad" = "${config.user.defaults.terminal} -e ${config.user.defaults.editor}";
    "$obs" = "obs";
  };
in {
  config = lib.mkIf config.user.ui.hyprland.enable {
    usr.files.".config/hypr/hyprland.conf" = {
      clobber = true;
      text = lib.mkBefore (genLib.toHyprconf {
        attrs = variablesConfig;
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
