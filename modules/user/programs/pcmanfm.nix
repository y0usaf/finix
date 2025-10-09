{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.pcmanfm = {
    enable = lib.mkEnableOption "pcmanfm file manager";
  };
  config = lib.mkIf config.user.programs.pcmanfm.enable {
    environment.systemPackages = [
      pkgs.pcmanfm
    ];
  };
}
