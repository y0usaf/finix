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

    ###########################################################################
    # Systemd Services
    ###########################################################################
    systemd.user.services.nixos-git-sync = {
      Unit = {
        Description = "Sync NixOS config changes after successful build";
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = false;
        Environment = [
          "PATH=${lib.makeBinPath [pkgs.git pkgs.coreutils pkgs.openssh]}"
          "SSH_AUTH_SOCK=%t/ssh-agent"
        ];

        ExecStart = pkgs.writeShellScript "nixos-git-sync" ''
          # Enable debug output for logging
          set -x

          # Sleep briefly to ensure all file writes are complete
          sleep 2

          # Switch to the NixOS configuration repository directory
          cd ${hostSystem.cfg.system.homeDirectory}/nixos

          # Assess if there are any changes (tracked or untracked)
          if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
            # Capture diff status of tracked files
            DIFF_STATUS=$(git diff --name-status HEAD)
            
            # Capture list of untracked files and format them as "A" (added)
            UNTRACKED=$(git ls-files --others --exclude-standard | sed 's/^/A /')
            
            # Combine both lists
            DIFF_LIST="$DIFF_STATUS"
            if [ -n "$UNTRACKED" ]; then
              if [ -n "$DIFF_LIST" ]; then
                DIFF_LIST="$DIFF_LIST\n$UNTRACKED"
              else
                DIFF_LIST="$UNTRACKED"
              fi
            fi
            
            # Create commit message with timestamp and diff list
            COMMIT_MSG="🤖 Auto Update: $(date '+%d/%m/%y@%H:%M:%S')"
            if [ -n "$DIFF_LIST" ]; then
              COMMIT_MSG="$COMMIT_MSG\n\nChanged files:\n$DIFF_LIST"
            fi
            
            # Stage all changes
            git add .
            
            # Commit with the formatted message
            git commit -m "$COMMIT_MSG"
            
            # Force push committed changes to the remote main branch
            git push origin main --force
          else
            echo "No changes to commit"
          fi
        '';
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
