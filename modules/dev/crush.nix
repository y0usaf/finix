{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.crush = {
    enable = lib.mkEnableOption "crush package";
  };

  config = lib.mkIf config.user.dev.crush.enable {
    environment.systemPackages = [
      pkgs.crush
    ];
  };
}
