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
      url."git@github.com:".pushInsteadOf = "https://github.com/"; # Force SSH for pushes
    };
  };

  # Ensure SSH agent is available
  services.ssh-agent.enable = true;

  # Generate and configure SSH key if it doesn't exist
  home.activation = {
    setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      REPO_PATH="${globals.homeDirectory}/nixos"
      SSH_KEY_PATH="${globals.homeDirectory}/Tokens/id_rsa_y0usaf"

      # Initialize git repo if needed
      mkdir -p "$REPO_PATH"
      if [ ! -d "$REPO_PATH/.git" ]; then
        $DRY_RUN_CMD git -C "$REPO_PATH" init
        $DRY_RUN_CMD git -C "$REPO_PATH" config user.email "${globals.gitEmail}"
        $DRY_RUN_CMD git -C "$REPO_PATH" config user.name "${globals.gitName}"
        $DRY_RUN_CMD git -C "$REPO_PATH" remote add origin "${globals.homeManagerRepoUrl}"

        # Create initial commit if repo is empty
        if [ -z "$(git -C "$REPO_PATH" rev-parse --verify HEAD 2>/dev/null)" ]; then
          $DRY_RUN_CMD git -C "$REPO_PATH" add .
          $DRY_RUN_CMD git -C "$REPO_PATH" commit -m "initial: NixOS configuration"

          # Try to push, but don't fail if it doesn't work (might need manual push first time)
          export SSH_AUTH_SOCK="/run/user/$(id -u)/ssh-agent"
          ${pkgs.openssh}/bin/ssh-add "$SSH_KEY_PATH" 2>/dev/null
          $DRY_RUN_CMD git -C "$REPO_PATH" push -u origin main || echo "Initial push failed - you may need to push manually first time"
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
        "PATH=${pkgs.git}/bin:${pkgs.coreutils}/bin"
        "SSH_AUTH_SOCK=%t/ssh-agent"
      ];
      # Add explicit SSH key path
      ExecStartPre = "${pkgs.openssh}/bin/ssh-add ${globals.homeDirectory}/Tokens/id_rsa_y0usaf";
      ExecStart = pkgs.writeShellScript "nixos-git-sync" ''
        cd ${globals.homeDirectory}/nixos
        if ! git diff --quiet HEAD; then
          git add .
          git commit -m "auto: system update $(date '+%Y-%m-%d %H:%M:%S')"
          git push -f origin main
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
      PathChanged = "${globals.homeDirectory}/nixos/result";
      Unit = "nixos-git-sync.service";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
