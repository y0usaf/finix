{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.pcmanfm;
in {
  options.home.programs.pcmanfm = {
    enable = lib.mkEnableOption "pcmanfm file manager";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pcmanfm
    ];
  };
}
