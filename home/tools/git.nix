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
  lib,

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

    nixos-git-sync = {
      enable = lib.mkEnableOption "automatic NixOS configuration git sync";

      nixosRepoUrl = lib.mkOption {
        type = lib.types.str;
        description = "URL of the NixOS configuration repository.";
      };

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "${config.cfg.shared.homeDirectory}/nixos";
        description = "Path to the NixOS configuration repository.";
      };

      remoteBranch = lib.mkOption {
        type = lib.types.str;
        default = "main";
        description = "The remote branch to push changes to.";
      };
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
          inherit (hostHome.cfg.defaults) editor;
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
    home.activation = lib.mkIf (cfg.nixos-git-sync.enable && (cfg.nixos-git-sync.nixosRepoUrl != null)) {
      setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
        # Only clone if the specified repository directory does not exist
        if [ ! -d "${cfg.nixos-git-sync.repoPath}" ]; then
          echo "Setting up NixOS configuration repository..."
          git clone ${cfg.nixos-git-sync.nixosRepoUrl} ${cfg.nixos-git-sync.repoPath}
        fi
      '';
    };

    # Note: Git sync functionality is in the nixos-git-sync module
    # See home/modules/tools/nixos-git-sync.nix for implementation
  };
}
