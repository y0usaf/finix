{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOption;
  inherit (lib.types) str bool submodule listOf;
  homeDir = config.user.homeDirectory;
  mkOpt = type: description: mkOption {inherit type description;};
  dirModule = submodule {
    options = {
      path = mkOption {
        type = str;
        description = "Absolute path to the directory";
      };
      create = mkOption {
        type = bool;
        default = true;
        description = "Whether to create the directory if it doesn't exist";
      };
    };
  };
in {
  options.user.paths = {
    wallpapers = mkOpt (submodule {
      options = {
        static = mkOpt dirModule "Wallpaper directory for static images.";
        video = mkOpt dirModule "Wallpaper directory for videos.";
      };
    }) "Wallpaper directories configuration";
    bookmarks = mkOption {
      type = listOf str;
      default = [
        "file://${homeDir}/Downloads Downloads"
        "file://${homeDir}/Documents Documents"
        "file://${homeDir}/Dev Dev"
        "file://${homeDir}/nixos NixOS"
        "file:///tmp tmp"
      ];
      description = "GTK bookmarks for file manager";
    };
  };

  config.user.paths.wallpapers = {
    static = mkDefault {
      path = "${homeDir}/DCIM/Wallpapers";
    };
    video = mkDefault {
      path = "${homeDir}/DCIM/Wallpapers_Video";
    };
  };
}
