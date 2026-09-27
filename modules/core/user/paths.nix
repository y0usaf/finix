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
    bookmarks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "file://${homeDir}/Downloads Downloads"
        "file://${homeDir}/Documents Documents"
        "file://${homeDir}/dev dev"
        "file://${homeDir}/finix Finix"
        "file:///tmp tmp"
      ];
      description = "GTK bookmarks for file manager";
    };
  };
}
