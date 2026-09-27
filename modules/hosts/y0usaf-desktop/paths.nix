{config, ...}: let
  homeDir = config.user.homeDirectory;
in {
  user.paths = {
    wallpapers = "${homeDir}/DCIM/Wallpapers/32_9/";
  };
}
