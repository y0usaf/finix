#═══════════════════════════ 🔧 DIRECTORIES MODULE 🔧 ═══════════════════════════#
{
  config,
  lib,
  pkgs,
  inputs,
  hostSystem,
  hostHome,
  ...
}: let
  helpers = import ../../lib/helpers/module-defs.nix {inherit lib;};
  inherit (helpers) t mkOpt dirModule;
in {
  options.cfg.directories = {
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
