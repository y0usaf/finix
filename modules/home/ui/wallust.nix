{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.ui.wallust;
in {
  options.home.ui.wallust = {
    enable = lib.mkEnableOption "wallust color generation";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = with pkgs; [
      wallust
    ];
  };
}
