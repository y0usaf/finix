{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };
  config = lib.mkIf config.user.programs.creative.enable {
    environment.systemPackages = [
      pkgs.pinta
      pkgs.gimp
    ];
  };
}
