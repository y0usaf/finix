{
  config,
  pkgs,
  lib,
  ...
}: {
  options.gaming.launchers = {
    lutris.enable = lib.mkEnableOption "Lutris gaming platform";
    heroic.enable = lib.mkEnableOption "Heroic Games Launcher";
  };

  config = {
    environment.systemPackages =
      lib.optional config.gaming.launchers.lutris.enable pkgs.lutris
      ++ lib.optional config.gaming.launchers.heroic.enable pkgs.heroic;
  };
}
