{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOption;
  inherit (lib.types) str submodule listOf;
  homeDir = config.user.homeDirectory;
  mkOpt = type: description: mkOption {inherit type description;};
  dirModule = submodule {
    options = {
      path = mkOption {
        type = str;
        description = "Absolute path to the directory";
      };
    };
  };
in {
  options.user.paths = {
    wallpapers = mkOpt (submodule {
      options = {
        static = mkOpt dirModule "Wallpaper directory for static images.";
      };
    }) "Wallpaper directories configuration";
    bookmarks = mkOption {
      type = listOf str;
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

  config.user.paths.wallpapers = {
    static = mkDefault {
      path = "${homeDir}/DCIM/Wallpapers";
    };
  };
}
