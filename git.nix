{
  config,
  pkgs,
  lib,
  globals,
  ...
}: {
  # Git configuration
  programs.git = {
    enable = true;
    userName = globals.gitName;
    userEmail = globals.gitEmail;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    };
  };

  # Ensure SSH agent is available
  services.ssh-agent.enable = true;

  # Generate and configure SSH key if it doesn't exist
  home.activation = {
    setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      REPO_PATH="${globals.homeDirectory}/nixos"
      SSH_KEY_PATH="${globals.homeDirectory}/Tokens/id_rsa_y0usaf"
      REPO_SSH_URL="${globals.homeManagerRepoUrl}"

      # Ensure SSH agent has our key
      export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
      ${pkgs.openssh}/bin/ssh-add "$SSH_KEY_PATH" 2>/dev/null

      # Initialize git repo if needed
      mkdir -p "$REPO_PATH"
      if [ ! -d "$REPO_PATH/.git" ]; then
        # Try to clone first, if that fails, assume repo doesn't exist
        if ! ${pkgs.git}/bin/git clone "$REPO_SSH_URL" "$REPO_PATH.tmp" 2>/dev/null; then
          # Create new repo
          $DRY_RUN_CMD git -C "$REPO_PATH" init
          $DRY_RUN_CMD git -C "$REPO_PATH" config user.email "${globals.gitEmail}"
          $DRY_RUN_CMD git -C "$REPO_PATH" config user.name "${globals.gitName}"
          $DRY_RUN_CMD git -C "$REPO_PATH" remote add origin "$REPO_SSH_URL"

          # Create initial commit
          $DRY_RUN_CMD git -C "$REPO_PATH" add .
          $DRY_RUN_CMD git -C "$REPO_PATH" commit -m "initial: NixOS configuration"

          # Create bare repo on remote
          REPO_NAME=$(basename "$REPO_SSH_URL" .git)
          REMOTE_PATH="/tmp/$REPO_NAME.git"
          ${pkgs.git}/bin/git init --bare "$REMOTE_PATH"

          # Push to the bare repo
          $DRY_RUN_CMD git -C "$REPO_PATH" push "$REMOTE_PATH" main

          # Push the bare repo to GitHub
          cd "$REMOTE_PATH"
          $DRY_RUN_CMD git push --mirror "$REPO_SSH_URL" || {
            echo "Initial repo setup complete locally. To finish setup:"
            echo "1. Create an empty repo on GitHub at: $REPO_SSH_URL"
            echo "2. Run 'home-manager switch' again"
            exit 1
          }
        else
          # If clone worked, move contents and clean up
          mv "$REPO_PATH.tmp/.git" "$REPO_PATH/"
          rm -rf "$REPO_PATH.tmp"
        fi
      fi
    '';
  };

  # Systemd service for auto-pushing after successful builds
  systemd.user.services.nixos-git-sync = {
    Unit = {
      Description = "Sync NixOS config changes after successful build";
      After = "format-nix.service";
      Requires = "ssh-agent.service";
    };
    Service = {
      Type = "oneshot";
      Environment = [
        "PATH=${lib.makeBinPath [pkgs.git pkgs.coreutils pkgs.openssh]}"
        "SSH_AUTH_SOCK=%t/ssh-agent"
      ];
      ExecStart = pkgs.writeShellScript "nixos-git-sync" ''
        # Ensure SSH agent has our key
        if ! ssh-add -l | grep -q "${globals.homeDirectory}/Tokens/id_rsa_y0usaf"; then
          ssh-add "${globals.homeDirectory}/Tokens/id_rsa_y0usaf"
        fi

        cd ${globals.homeDirectory}/nixos
        # Check if there are any changes, including untracked files
        if ! git diff --quiet HEAD || [ -n "$(git ls-files --others --exclude-standard)" ]; then
          git add .
          git commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')"
          git push origin main
        fi
      '';
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.paths.nixos-git-sync = {
    Unit = {
      Description = "Watch NixOS config directory for successful builds";
    };
    Path = {
      PathModified = "${globals.homeDirectory}/nixos";
      Unit = "nixos-git-sync.service";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
