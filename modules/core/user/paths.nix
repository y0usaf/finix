{
  config,
  lib,
  ...
}: let
  homeDir = config.user.homeDirectory;
in {
  options.user.paths = {
    steam = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/.local/share/Steam";
      description = "Directory for Steam.";
    };
    wallpapers = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/DCIM/Wallpapers";
      description = "Wallpaper directory for static images.";
    };
  };
}
