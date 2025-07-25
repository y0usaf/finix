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
    users.users.${config.user.name}.maid.packages = with pkgs; [
      pcmanfm
    ];
  };
}
