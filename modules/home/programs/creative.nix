{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.programs.creative;
in {
  options.home.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = with pkgs; [
      pinta
      gimp
    ];
  };
}
