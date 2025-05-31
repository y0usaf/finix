###############################################################################
# LaTeX Development Module
# Provides LaTeX development environment with essential packages and editors
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.dev.latex;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      # LaTeX Distribution
      texliveFull # Comprehensive TeX Live distribution

      # LaTeX Editors
      texstudio # Feature-rich LaTeX editor

      # Additional Tools
      tectonic
    ];
  };
}
