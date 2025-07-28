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
    hjem.users.${config.user.name}.packages = [pkgs.vesktop];
  };
}
