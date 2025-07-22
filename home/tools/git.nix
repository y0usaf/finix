###############################################################################
# Git Configuration & Automation (Maid Version)
# Manages Git setup, SSH integration, and repository automation
# - User configuration (name, email, editor)
# - SSH agent integration via systemd
# - Repository auto-setup
# - Automatic sync service
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.git;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.tools.git = {
    enable = lib.mkEnableOption "git configuration and automation";

    name = lib.mkOption {
      type = lib.types.str;
      description = "Git username.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      description = "Git email address.";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "nvim";
      description = "Default editor for git.";
    };

    nixos-git-sync = {
      enable = lib.mkEnableOption "automatic NixOS configuration git sync";

      nixosRepoUrl = lib.mkOption {
        type = lib.types.str;
        description = "URL of the NixOS configuration repository.";
      };

      repoPath = lib.mkOption {
        type = lib.types.str;
        default = "/home/y0usaf/nixos";
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
    users.users.y0usaf.maid = {
      ###########################################################################
      # Packages
      ###########################################################################
      packages = with pkgs; [
        git
        openssh
      ];

      ###########################################################################
      # Configuration Files
      ###########################################################################
      file.home = {
        # Git Configuration
        ".gitconfig".text = ''
          [user]
            name = ${cfg.name}
            email = ${cfg.email}

          [core]
            editor = ${cfg.editor}

          [init]
            defaultBranch = main

          [pull]
            rebase = true

          [push]
            autoSetupRemote = true

          [url "git@github.com:"]
            pushInsteadOf = https://github.com/
        '';

        # Repository Setup Script
        ".local/share/bin/setup-nixos-repo" = lib.mkIf (cfg.nixos-git-sync.enable && (cfg.nixos-git-sync.nixosRepoUrl != "")) {
          text = ''
            #!/bin/bash
            # Setup NixOS repository if it doesn't exist
            if [ ! -d "${cfg.nixos-git-sync.repoPath}" ]; then
              echo "Setting up NixOS configuration repository..."
              git clone ${cfg.nixos-git-sync.nixosRepoUrl} ${cfg.nixos-git-sync.repoPath}
            fi
          '';
          executable = true;
        };

        # Git Sync Script
        ".local/share/bin/nixos-git-sync" = lib.mkIf cfg.nixos-git-sync.enable {
          text = ''
            #!/bin/bash
            # Enable debug output for logging
            set -x

            # Sleep briefly to ensure all file writes are complete
            sleep 2

            # Get repository path
            REPO_PATH="${cfg.nixos-git-sync.repoPath}"

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

              # Replace date placeholder in commit message format
              COMMIT_MSG="🤖 Auto Update: $FORMATTED_DATE"

              # Commit with the formatted message
              git commit -m "$COMMIT_MSG"

              # Push to the configured remote branch
              git push origin ${cfg.nixos-git-sync.remoteBranch} --force
            else
              echo "No changes to commit"
            fi
          '';
          executable = true;
        };

        # Shell Integration
        ".config/zsh/.zshrc".text = lib.mkIf cfg.nixos-git-sync.enable ''

          # Git sync function
          git-sync() {
            $HOME/.local/share/bin/nixos-git-sync
          }
        '';
      };
    };
  };
}
