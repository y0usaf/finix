###############################################################################
# Creative Applications Module
# Provides creative and image editing applications
# - Simple painting tools
# - Advanced image editing
# - Digital art creation
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.programs.creative;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      pinta # Simple painting application
      gimp # Feature-rich image editor
    ];
  };
}
