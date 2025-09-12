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
    usr.packages = with pkgs; [
      pinta
      gimp
    ];
  };
}
