###############################################################################
# Creative Applications Module (Nix-Maid Version)
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
  cfg = config.home.programs.creative;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.creative = {
    enable = lib.mkEnableOption "creative applications module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    users.users.y0usaf.maid.packages = with pkgs; [
      pinta # Simple painting application
      gimp # Feature-rich image editor
    ];
  };
}
