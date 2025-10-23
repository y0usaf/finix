{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.stremio = {
    enable = lib.mkEnableOption "Stremio media center";
  };
  config = lib.mkIf config.user.programs.stremio.enable {
    environment.systemPackages = [pkgs.stremio];
  };
}
