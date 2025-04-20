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
  host,
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
          editor = host.cfg.defaults.editor;
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
        if [ ! -d "${config.cfg.system.homeDirectory}/nixos" ]; then
          echo "Setting up NixOS configuration repository..."
          git clone ${cfg.homeManagerRepoUrl} ${config.cfg.system.homeDirectory}/nixos
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
          cd ${config.cfg.system.homeDirectory}/nixos

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

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
