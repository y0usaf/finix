###############################################################################
# Development Shell Integration Module
# Example of how other modules can contribute to shell configuration
# Adds development-specific environment variables, aliases, and functions
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.dev.shell-integration;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.shell-integration = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development shell integration";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # TODO: Update this module to use the new file registry system
    # For now, this module is disabled while we get the basic system working
    
    # Example of how to migrate to file registry:
    # fileRegistry.content.zshenv.dev-env = ''...'';  
    # fileRegistry.content.zshrc.dev-functions = ''...'';  
    # fileRegistry.content.zshrc.dev-aliases = ''...'';
  };
}