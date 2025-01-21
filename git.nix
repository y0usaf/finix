#===============================================================================
#                      🔄 Git Configuration & Automation 🔄
#===============================================================================
# 👤 User settings
# 🔑 SSH integration
# 📦 Repository management
# 🔄 Auto-sync
# 🚀 Service automation
#===============================================================================
{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  #── 👤 Git Configuration ─────────────────#
  programs.git = {
    enable = true;
    userName = globals.gitName;
    userEmail = globals.gitEmail;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".pushInsteadOf = "https://github.com/";
      core.editor = globals.defaultEditor; # Added for consistency
    };
  };

  #── 🔑 SSH Integration ───────────────────#
  services.ssh-agent.enable = true;

  #── 📦 Repository Setup ──────────────────#
  home.activation = {
    setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ ! -d "${globals.homeDirectory}/nixos" ]; then
        echo "Setting up NixOS configuration repository..."
        git clone ${globals.homeManagerRepoUrl} ${globals.homeDirectory}/nixos
      fi
    '';
  };

  #── 🔄 Auto-Sync Service ────────────────#
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
        # Add debug logging
        set -x

        # Sleep briefly to ensure all files are written
        sleep 2

        cd ${globals.homeDirectory}/nixos
        # Check if there are any changes, including untracked files
        if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
          git add .
          git commit -m "auto: system update $(date '+%d/%m/%y@%H:%M:%S')"
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
}
