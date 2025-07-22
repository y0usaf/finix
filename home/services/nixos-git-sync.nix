{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.nixosGitSync;
in {
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
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      systemd.services."nixos-git-sync" = {
        description = "Sync NixOS configuration changes after successful build";
        script = ''
                    set -x
                    sleep 2
                    REPO_PATH="${cfg.repoPath}"
                    if [ ! -d "$REPO_PATH" ]; then
                      echo "Repository directory does not exist: $REPO_PATH"
                      exit 1
                    fi
                    cd "$REPO_PATH"
                    if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
                      git add .
                      FORMATTED_DATE=$(date '+%d/%m/%y@%H:%M:%S')
                      CHANGED_FILES=$(git diff --cached --name-status | sed 's/^\(.*\)\t\(.*\)$/- [\1] \2/')
                      COMMIT_MSG="🤖 Auto Update: $FORMATTED_DATE
          Files changed:
          $CHANGED_FILES"
                      git commit -m "$COMMIT_MSG"
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
