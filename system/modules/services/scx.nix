###############################################################################
# SCX Service Configuration
# System scheduling and tuning service:
# - SCX scheduler configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    ###########################################################################
    # SCX Custom Service
    # System scheduling and tuning service
    ###########################################################################
    services.scx = {
      enable = true; # Activate the SCX service.
      scheduler = "scx_lavd"; # Specify the scheduler mode.
      package = pkgs.scx.rustscheds; # Use the rust-based scheduler package.
    };
  };
}
