{
  config,
  lib,
  ...
}: let
  cfg = config.home.gaming.clair-obscur;
in {
  imports = [
    ./gameusersettings.nix
    ./plugin.nix
    ./engine.nix
    ./scalability.nix
  ];

  options.home.gaming.clair-obscur = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur configuration and ClairObscurFix plugin";
    };
  };

  config = lib.mkIf cfg.enable {
    home.gaming.clair-obscur.gameusersettings.enable = true;
    home.gaming.clair-obscur.plugin.enable = true;
    home.gaming.clair-obscur.engine.enable = true;
    home.gaming.clair-obscur.scalability.enable = true;
  };
}
