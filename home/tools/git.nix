{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.tools.git;
in {
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
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        git
        openssh
      ];
      file.home = {
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
        ".local/share/bin/setup-nixos-repo" = lib.mkIf (cfg.nixos-git-sync.enable && (cfg.nixos-git-sync.nixosRepoUrl != "")) {
          text = ''
            if [ ! -d "${cfg.nixos-git-sync.repoPath}" ]; then
              echo "Setting up NixOS configuration repository..."
              git clone ${cfg.nixos-git-sync.nixosRepoUrl} ${cfg.nixos-git-sync.repoPath}
            fi
          '';
          executable = true;
        };
        ".local/share/bin/nixos-git-sync" = lib.mkIf cfg.nixos-git-sync.enable {
          text = ''
            set -x
            sleep 2
            REPO_PATH="${cfg.nixos-git-sync.repoPath}"
            if [ ! -d "$REPO_PATH" ]; then
              echo "Repository directory does not exist: $REPO_PATH"
              exit 1
            fi
            cd "$REPO_PATH"
            if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
              git add .
              FORMATTED_DATE=$(date '+%d/%m/%y@%H:%M:%S')
              COMMIT_MSG="🤖 Auto Update: $FORMATTED_DATE"
              git commit -m "$COMMIT_MSG"
              git push origin ${cfg.nixos-git-sync.remoteBranch} --force
            else
              echo "No changes to commit"
            fi
          '';
          executable = true;
        };
        ".config/zsh/.zshrc".text = lib.mkIf cfg.nixos-git-sync.enable ''
          git-sync() {
            $HOME/.local/share/bin/nixos-git-sync
          }
        '';
      };
    };
  };
}
