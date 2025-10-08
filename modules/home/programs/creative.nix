{
  config,
  pkgs,
  lib,
  ...
}: {
  options.home.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };
  config = lib.mkIf config.home.programs.creative.enable {
    environment.systemPackages = [
      pkgs.pinta
      pkgs.gimp
    ];
  };
}
