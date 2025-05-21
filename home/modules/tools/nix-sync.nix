###############################################################################
# NixOS Configuration Auto-Sync
# Manages automatic git operations for NixOS configuration
# - Automatic change detection
# - Customizable commit messages
# - Configurable git operations (commit, push)
# - Branch management
###############################################################################
{
  config,
  pkgs,
  lib,
  hostSystem,
  ...
}: let
  cfg = config.cfg.tools.nix-sync;
  gitCfg = config.cfg.tools.git;
  
  # Determine if git module is enabled
  gitEnabled = config.cfg.tools.git.enable or false;
  
  # Helper to get home directory path
  homeDir = hostSystem.cfg.system.homeDirectory;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.tools.nix-sync = {
    enable = lib.mkEnableOption "automatic NixOS configuration git sync";

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "${homeDir}/nixos";
      description = "Path to the NixOS configuration repository.";
    };

    commitMessageFormat = lib.mkOption {
      type = lib.types.str;
      default = "🤖 Auto Update: %DATE%";
      description = ''
        Format for commit messages. %DATE% will be replaced with the current date/time.
        Changed files will be automatically appended to the message.
      '';
    };

    autoCommit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically commit changes.";
    };

    autoPush = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically push changes.";
    };

    remoteBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "The remote branch to push changes to.";
    };

    forcePush = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to use force push when pushing changes.";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # The service configuration
    systemd.user.services.nixos-git-sync = {
      Unit = {
        Description = "Sync NixOS configuration changes after successful build";
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

          # Get repository path
          REPO_PATH="${cfg.repoPath}"

          # Check if repository exists
          if [ ! -d "$REPO_PATH" ]; then
            echo "Repository directory does not exist: $REPO_PATH"
            exit 1
          fi

          # Switch to the NixOS configuration repository directory
          cd "$REPO_PATH"

          # Assess if there are any changes (tracked or untracked)
          if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
            # Capture diff status of tracked files
            DIFF_STATUS=$(git diff --name-status HEAD)
            
            # Capture list of untracked files and format them as "A" (added)
            UNTRACKED=$(git ls-files --others --exclude-standard | sed 's/^/A /')
            
            # Create a temporary file for the commit message
            COMMIT_MSG_FILE=$(mktemp)
            
            # Format date for commit message
            FORMATTED_DATE=$(date '+%d/%m/%y@%H:%M:%S')
            
            # Replace date placeholder in commit message format
            COMMIT_MSG="$(echo "${cfg.commitMessageFormat}" | sed "s/%DATE%/$FORMATTED_DATE/g")"
            
            # Write the header to the commit message file
            echo "$COMMIT_MSG" > "$COMMIT_MSG_FILE"
            
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
            
            # Only perform git operations if autoCommit is enabled
            if [ "${toString cfg.autoCommit}" = "true" ]; then
              # Stage all changes
              git add .
              
              # Commit with the formatted message from the file
              git commit -F "$COMMIT_MSG_FILE"
              
              # Only push if autoPush is enabled
              if [ "${toString cfg.autoPush}" = "true" ]; then
                # Push to the configured remote branch
                if [ "${toString cfg.forcePush}" = "true" ]; then
                  git push origin ${cfg.remoteBranch} --force
                else
                  git push origin ${cfg.remoteBranch}
                fi
              fi
            fi
            
            # Clean up temporary file
            rm "$COMMIT_MSG_FILE"
          else
            echo "No changes to commit"
          fi
        '';
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };

    # Recommend enabling the SSH agent if using autoPush but not using git module
    warnings = lib.optional (cfg.autoPush && !gitEnabled) 
      "nix-sync: autoPush is enabled but git module is not. You may need to configure SSH agent manually.";
  };
}