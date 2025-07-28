{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.gaming.controllers;
in {
  options.home.gaming.controllers = {
    enable = lib.mkEnableOption "gaming controller support";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = with pkgs; [
      dualsensectl
    ];
  };
}
