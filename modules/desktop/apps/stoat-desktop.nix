{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.stoat-desktop = {
    enable = lib.mkEnableOption "stoat-desktop";
  };

  config = lib.mkIf config.user.programs.stoat-desktop.enable {
    environment.systemPackages = [pkgs.stoat-desktop];
  };
}
