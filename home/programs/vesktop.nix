###############################################################################
# Vesktop Module (Maid)
# Alternate Discord client with Vencord built-in
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.home.programs.vesktop;
  md = config.md;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.programs.vesktop = {
    enable = lib.mkEnableOption "Vesktop (Discord client) module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    md.packages = [pkgs.vesktop];
  };
}
