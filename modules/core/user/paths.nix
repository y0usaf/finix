{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOption;
  inherit (lib.types) str bool submodule;
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
    flake = mkOpt dirModule "The directory where the flake lives.";
    music = mkOpt dirModule "Directory for music files.";
    dcim = mkOpt dirModule "Directory for pictures (DCIM).";
    steam = mkOpt dirModule "Directory for Steam.";
  };

  config = {
    user = {
      paths = {
        flake = mkDefault {
          path = "${homeDir}/nixos";
        };
        steam = mkDefault {
          path = "${homeDir}/.local/share/Steam";
        };
      };
    };
  };
}
