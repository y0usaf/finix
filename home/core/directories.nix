#═══════════════════════════ 🔧 DIRECTORIES MODULE 🔧 ═══════════════════════════#
{lib, ...}: let
  inherit (lib) t mkOpt dirModule;
in {
  options.home.directories = {
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
