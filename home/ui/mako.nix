{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.cfg.ui.mako;
in {
  options.cfg.ui.mako = {
    enable = mkEnableOption "Mako notification daemon";
  };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      # All the standard mako settings with your preferred defaults
      settings = {
        actions = true;
        anchor = "top-right";
        "background-color" = "#2e3440";
        "border-color" = "#88c0d0";
        "border-radius" = 5;
        "border-size" = 1;
        "default-timeout" = 5000;
        format = "<b>%s</b>\\n%b";
        "group-by" = null;
        height = 100;
        "icon-path" = null;
        icons = true;
        "ignore-timeout" = false;
        layer = "top";
        margin = "10";
        markup = true;
        "max-icon-size" = 64;
        "max-visible" = 5;
        output = null;
        padding = "5";
        "progress-color" = null;
        sort = "-time";
        "text-color" = "#eceff4";
        width = 300;
      };
    };
  };
}
