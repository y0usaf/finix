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
  profile,
  ...
}: {
  #===================================================================
  #                      Git User Configuration
  #===================================================================
  # Enable Git and configure user settings as defined in the profile.
  programs.git = {
    enable = true;
    userName = profile.gitName;
    userEmail = profile.gitEmail;

    #-----------------------------------------------------------------
    # Extra Git Configurations:
    #  - Default branch name is "main".
    #  - Always perform a rebase on pull.
    #  - Configure remote setup behavior on push.
    #  - Use SSH URLs in place of HTTPS for GitHub.
    #  - Set the default editor based on the profile.
    #-----------------------------------------------------------------
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".pushInsteadOf = "https://github.com/";
      core.editor = profile.defaultEditor;
    };
  };

  #===================================================================
  #                           SSH Agent Activation
  #===================================================================
  # Enable the SSH agent service for handling keys.
  services.ssh-agent.enable = true;

  #===================================================================
  #                  Repository Setup & Activation
  #===================================================================
  # Upon Home Manager activation, clone the NixOS configuration repo if absent.
  home.activation = {
    setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Only clone if the "nixos" directory does not exist within homeDirectory.
      if [ ! -d "${profile.homeDirectory}/nixos" ]; then
        echo "Setting up NixOS configuration repository..."
        git clone ${profile.gitHomeManagerRepoUrl} ${profile.homeDirectory}/nixos
      fi
    '';
  };

  #===================================================================
  #                     Auto-Sync Service Setup
  #===================================================================
  # Define a user-level systemd oneshot service to sync Git changes post build.
  systemd.user.services.nixos-git-sync = {
    Unit = {
      # Description for systemd about what this service does.
      Description = "Sync NixOS config changes after successful build";
    };

    Service = {
      Type = "oneshot"; # Run the sync process as a one-off task.
      RemainAfterExit = false;

      #-----------------------------------------------------------------
      # Environment variables configured for the Git sync script.
      # - PATH includes git, coreutils, and openssh binaries.
      # - SSH_AUTH_SOCK points to the SSH agent socket.
      #-----------------------------------------------------------------
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.git pkgs.coreutils pkgs.openssh]}"
        "SSH_AUTH_SOCK=%t/ssh-agent"
      ];

      #-----------------------------------------------------------------
      # Script to perform:
      #   - A brief sleep ensures all file operations are finalized.
      #   - Changes are checked (including untracked files).
      #   - If changes exist, add, commit (with a timestamp), and force push.
      #-----------------------------------------------------------------
      ExecStart = pkgs.writeShellScript "nixos-git-sync" ''
        # Enable debug output for logging
        set -x

        # Sleep briefly to ensure all file writes are complete
        sleep 2

        # Switch to the NixOS configuration repository directory
        cd ${profile.homeDirectory}/nixos

        # Assess if there are any changes (tracked or untracked)
        if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
          # Stage all changes
          git add .
          # Commit with a timestamp included in the message
          git commit -m "🤖 Auto Update: $(date '+%d/%m/%y@%H:%M:%S')"
          # Force push committed changes to the remote main branch
          git push origin main --force
        else
          echo "No changes to commit"
        fi
      '';
    };

    #-----------------------------------------------------------------
    # Setup instructions for systemd to start this service.
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
