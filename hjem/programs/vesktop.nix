###############################################################################
# Vesktop Module  
# Alternate Discord client with Vencord built-in
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.programs.vesktop;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.vesktop = {
    enable = lib.mkEnableOption "Vesktop (Discord client) module";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vesktop;
      description = "The vesktop package to use.";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = [cfg.package];
  };
}