{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.sway-launcher-desktop;
in {
  options.modules.sway-launcher-desktop = {
    enable = mkEnableOption "sway-launcher-desktop script";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      fzf
    ];

    xdg.configFile."scripts/sway-launcher-desktop.sh" = {
      source = ../../pkg/scripts/sway-launcher-desktop.sh;
      executable = true;
      onChange = ''
        mkdir -p $HOME/.config/scripts
      '';
    };
  };
}
