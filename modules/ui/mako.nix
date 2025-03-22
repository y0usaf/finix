{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.ui.mako;
in {
  options.modules.ui.mako = {
    enable = mkEnableOption "Mako notification daemon";
  };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      # All the standard mako settings with your preferred defaults
      actions = true;
      anchor = "top-right";
      backgroundColor = "#2e3440";
      borderColor = "#88c0d0";
      borderRadius = 5;
      borderSize = 1;
      defaultTimeout = 5000;
      format = "<b>%s</b>\\n%b";
      groupBy = null;
      height = 100;
      iconPath = null;
      icons = true;
      ignoreTimeout = false;
      layer = "top";
      margin = "10";
      markup = true;
      maxIconSize = 64;
      maxVisible = 5;
      output = null;
      padding = "5";
      progressColor = null;
      sort = "-time";
      textColor = "#eceff4";
      width = 300;
    };
  };
}
