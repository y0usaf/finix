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
    hjem.users.${config.user.name}.packages = with pkgs; [
      pcmanfm
    ];
  };
}
