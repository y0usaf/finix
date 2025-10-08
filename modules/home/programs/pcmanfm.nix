{
  config,
  lib,
  pkgs,
  ...
}: {
  options.home.programs.pcmanfm = {
    enable = lib.mkEnableOption "pcmanfm file manager";
  };
  config = lib.mkIf config.home.programs.pcmanfm.enable {
    environment.systemPackages = [
      pkgs.pcmanfm
    ];
  };
}
