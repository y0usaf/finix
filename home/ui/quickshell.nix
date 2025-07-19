###############################################################################
# Quickshell Module
# Qt-based desktop shell
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.ui.quickshell;
  username = "y0usaf";
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.ui.quickshell = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Quickshell desktop shell";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        quickshell
        cava
      ];
    };
  };
}
