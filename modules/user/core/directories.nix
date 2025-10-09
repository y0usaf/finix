{lib, ...}: let
  # Define custom lib functions locally
  t = lib.types;
  mkOpt = type: description: lib.mkOption {inherit type description;};
  dirModule = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        description = "Absolute path to the directory";
      };
      create = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to create the directory if it doesn't exist";
      };
    };
  };
in {
  options.user.directories = {
    flake = mkOpt dirModule "The directory where the flake lives.";
    music = mkOpt dirModule "Directory for music files.";
    dcim = mkOpt dirModule "Directory for pictures (DCIM).";
    steam = mkOpt dirModule "Directory for Steam.";
    wallpapers = mkOpt (t.submodule {
      options = {
        static = mkOpt dirModule "Wallpaper directory for static images.";
        video = mkOpt dirModule "Wallpaper directory for videos.";
      };
    }) "Wallpaper directories configuration";
  };
}
