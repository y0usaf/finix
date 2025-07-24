{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.vesktop;
in {
  options.home.programs.vesktop = {
    enable = lib.mkEnableOption "Vesktop (Discord client) module";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid.packages = [pkgs.vesktop];
  };
}
