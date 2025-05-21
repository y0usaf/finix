###############################################################################
# Git Configuration & Automation
# Manages Git setup, SSH integration, and repository automation
# - User configuration (name, email, editor)
# - SSH agent integration
# - Repository auto-setup
# - Automatic sync service
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  hostHome,
  ...
}: let
  cfg = config.cfg.tools.git;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.tools.git = {
    enable = lib.mkEnableOption "git configuration and automation";
    name = lib.mkOption {
      type = lib.types.str;
      description = "Git username.";
    };
    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address.";
    };
    homeManagerRepoUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL of the Home Manager repository.";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Git Configuration
    ###########################################################################
    programs.git = {
      enable = true;
      userName = cfg.name;
      userEmail = cfg.email;

      extraConfig = {
        core = {
          editor = hostHome.cfg.defaults.editor;
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        url."git@github.com:".pushInsteadOf = "https://github.com/";
      };
    };

    ###########################################################################
    # SSH Agent Integration
    ###########################################################################
    services.ssh-agent.enable = true;

    ###########################################################################
    # Repository Setup
    ###########################################################################
    home.activation = {
      setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Only clone if the "nixos" directory does not exist within homeDirectory.
        if [ ! -d "${hostSystem.cfg.system.homeDirectory}/nixos" ]; then
          echo "Setting up NixOS configuration repository..."
          git clone ${cfg.homeManagerRepoUrl} ${hostSystem.cfg.system.homeDirectory}/nixos
        fi
      '';
    };

    # Note: Git sync functionality has been moved to the nix-sync module
    # See home/modules/tools/nix-sync.nix for configuration options
  };
}
