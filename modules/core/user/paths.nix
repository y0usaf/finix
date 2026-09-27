{
  config,
  lib,
  ...
}: let
  inherit (lib) mkDefault mkOption;
  inherit (lib.types) str submodule;
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
    flake = mkOpt dirModule "The directory where the flake lives.";
    steam = mkOpt dirModule "Directory for Steam.";
  };

  config = {
    user = {
      paths = {
        flake = mkDefault {
          path = "${homeDir}/finix";
        };
        steam = mkDefault {
          path = "${homeDir}/.local/share/Steam";
        };
      };
    };
  };
}
