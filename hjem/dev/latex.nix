###############################################################################
# LaTeX Development Module (Hjem Version)
# Provides LaTeX development environment with essential packages and editors
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.latex;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      # LaTeX Distribution
      texliveFull # Comprehensive TeX Live distribution

      # LaTeX Editors
      texstudio # Feature-rich LaTeX editor

      # Additional Tools
      tectonic
    ];
  };
}
