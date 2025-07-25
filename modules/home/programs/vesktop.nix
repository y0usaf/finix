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
    users.users.${config.user.name}.maid.packages = [pkgs.vesktop];
  };
}
