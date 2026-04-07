{
  lib,
  config,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.ui.hyprland.enable {
    bayt.users."${config.user.name}".files.".config/hypr/hyprland.conf" = {
      text = lib.mkBefore (genLib.toHyprconf {
        attrs = {
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
        importantPrefixes = ["$" "exec" "source"];
      });
    };
  };
}
