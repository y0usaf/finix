###############################################################################
# SSH Configuration Module
# Configures SSH client and agent for secure remote connections
# - SSH client configuration
# - SSH key management
# - GitHub connection setup
# - SSH agent service
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.cfg.core.ssh;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.core.ssh = {
    enable = lib.mkEnableOption "SSH configuration module";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # SSH Client Configuration
    ###########################################################################
    programs.ssh = {
      enable = true;

      extraConfig = ''
        SetEnv TERM=xterm-256color
      '';

      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/Tokens/id_rsa_y0usaf";
        };
      };
    };

    ###########################################################################
    # SSH Agent Service
    ###########################################################################
    services.ssh-agent.enable = true;
  };
}
