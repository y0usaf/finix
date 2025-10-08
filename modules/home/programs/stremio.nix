{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.stremio;
in {
  options.home.programs.stremio = {
    enable = lib.mkEnableOption "Stremio media center";
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.stremio];
  };
}
