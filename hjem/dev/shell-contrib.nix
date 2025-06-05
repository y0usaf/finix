###############################################################################
# Development Shell Contributions
# Shows how other modules can add to shell configuration
###############################################################################
{
  config,
  lib,
  ...
}: let
  cfg = config.cfg.hjome.dev.shell-contrib;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.shell-contrib = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable development shell contributions";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Contribute to environment variables (Hjem already supports this)
    environment.sessionVariables = {
      EDITOR = "code";
      BROWSER = "firefox";
    };
    
    # TODO: Migrate to file registry system
    # Old API:
    # cfg.hjome.shell.zsh.files.".zshrc".text = lib.mkAfter ''...''; 
    #
    # New file registry approach:
    # fileRegistry.content.zshrc.dev-aliases = ''...'';
    
    # Disabled until migration is complete
  };
}