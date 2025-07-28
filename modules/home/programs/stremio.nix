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
    hjem.users.${config.user.name}.packages = with pkgs; [stremio];
  };
}
