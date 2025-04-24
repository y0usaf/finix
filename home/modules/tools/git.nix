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
            
            # Create a temporary file for the commit message
            COMMIT_MSG_FILE=$(mktemp)
            
            # Write the header to the commit message file
            echo "🤖 Auto Update: $(date '+%d/%m/%y@%H:%M:%S')" > "$COMMIT_MSG_FILE"
            
            # If we have changes to report, add them to the commit message
            if [ -n "$DIFF_STATUS" ] || [ -n "$UNTRACKED" ]; then
              echo "" >> "$COMMIT_MSG_FILE"  # Add a blank line
              echo "Changed files:" >> "$COMMIT_MSG_FILE"
              
              # Add tracked changes if any
              if [ -n "$DIFF_STATUS" ]; then
                echo "$DIFF_STATUS" >> "$COMMIT_MSG_FILE"
              fi
              
              # Add untracked files if any
              if [ -n "$UNTRACKED" ]; then
                echo "$UNTRACKED" >> "$COMMIT_MSG_FILE"
              fi
            fi
            
            # Stage all changes
            git add .
            
            # Commit with the formatted message from the file
            git commit -F "$COMMIT_MSG_FILE"
            
            # Clean up temporary file
            rm "$COMMIT_MSG_FILE"
            
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
