{
  config,
  lib,
  ...
}: let
  homeDir = config.user.homeDirectory;
in {
  options.user.paths = {
    flake = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/finix";
      description = "The directory where the flake lives.";
    };
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
