###############################################################################
# LaTeX Development Module (Maid Version)
# Provides LaTeX development environment with essential packages and editors
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.home.programs.dev.latex;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.home.programs.dev.latex = {
    enable = lib.mkEnableOption "LaTeX development environment";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      # LaTeX Distribution
      texliveFull # Comprehensive TeX Live distribution

      # LaTeX Editors
      texstudio # Feature-rich LaTeX editor

      # Additional Tools
      tectonic
    ];
  };
}
