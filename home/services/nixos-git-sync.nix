###############################################################################
# NixOS Configuration Git Sync
# Automatic syncing of NixOS configuration changes
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.nixosGitSync;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.services.nixosGitSync = {
    enable = lib.mkEnableOption "NixOS configuration git sync service";

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/y0usaf/nixos";
      description = "Path to the NixOS configuration repository";
    };

    remoteBranch = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = "Remote branch to push to";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      systemd.services."nixos-git-sync" = {
        description = "Sync NixOS configuration changes after successful build";
        script = ''
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
                      # Stage all changes
                      git add .

                      # Format date for commit message
                      FORMATTED_DATE=$(date '+%d/%m/%y@%H:%M:%S')

                      # Get list of changed files with status
                      CHANGED_FILES=$(git diff --cached --name-status | sed 's/^\(.*\)\t\(.*\)$/- [\1] \2/')

                      # Create commit message with file list
                      COMMIT_MSG="🤖 Auto Update: $FORMATTED_DATE

          Files changed:
          $CHANGED_FILES"

                      # Commit with the formatted message
                      git commit -m "$COMMIT_MSG"

                      # Push to the configured remote branch
                      git push origin ${cfg.remoteBranch} --force
                    else
                      echo "No changes to commit"
                    fi
        '';
        serviceConfig.Type = "oneshot";
        path = with pkgs; [git coreutils openssh];
        environment = {
          SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent";
        };
        wantedBy = ["default.target"];
      };
    };
  };
}
