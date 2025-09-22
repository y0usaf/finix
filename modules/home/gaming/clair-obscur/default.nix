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
  ];

  options.home.gaming.clair-obscur = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Clair Obscur configuration";
    };
    
    enablePlugin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ClairObscurFix plugin installation";
    };
  };

  config = lib.mkIf cfg.enable {
    home.gaming.clair-obscur.gameusersettings.enable = true;
    home.gaming.clair-obscur.plugin.enable = cfg.enablePlugin;
  };
}
