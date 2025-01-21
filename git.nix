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
      After = ["home-manager-switch.service" "nixos-rebuild.service"];
      Wants = ["home-manager-switch.service" "nixos-rebuild.service"];
      Requires = ["ssh-agent.service"];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.git pkgs.coreutils pkgs.openssh]}"
        "SSH_AUTH_SOCK=%t/ssh-agent"
      ];
      ExecStart = pkgs.writeShellScript "nixos-git-sync" ''
        # Exit if neither service succeeded
        if ! (systemctl --user is-active --quiet home-manager-switch.service || systemctl is-active --quiet nixos-rebuild.service); then
          echo "Neither home-manager switch nor nixos-rebuild succeeded, skipping git sync"
          exit 0
        fi

        # Ensure SSH agent has our key
        if ! ssh-add -l | grep -q "${globals.homeDirectory}/Tokens/id_rsa_y0usaf"; then
          ssh-add "${globals.homeDirectory}/Tokens/id_rsa_y0usaf"
        fi

        cd ${globals.homeDirectory}/nixos
        # Check if there are any changes, including untracked files
        if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
          git add .
          git commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')"
          git push origin main --force
        fi
      '';
    };
    Install = {
      WantedBy = ["home-manager-switch.service" "nixos-rebuild.service"];
    };
  };
}
