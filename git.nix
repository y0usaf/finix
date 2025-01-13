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
    };
  };

  # Initial repo setup
  home.activation = {
    setupGitRepo = lib.hm.dag.entryAfter ["writeBoundary"] ''
      REPO_PATH="${globals.homeDirectory}/nixos"
      mkdir -p "$REPO_PATH"

      if [ ! -d "$REPO_PATH/.git" ]; then
        $DRY_RUN_CMD git -C "$REPO_PATH" init
        $DRY_RUN_CMD git -C "$REPO_PATH" config user.email "${globals.gitEmail}"
        $DRY_RUN_CMD git -C "$REPO_PATH" config user.name "${globals.gitName}"
        $DRY_RUN_CMD git -C "$REPO_PATH" remote add origin "${globals.homeManagerRepoUrl}"
      fi
    '';
  };

  # Systemd service for auto-pushing after successful builds
  systemd.user.services.nixos-git-sync = {
    Unit = {
      Description = "Sync NixOS config changes after successful build";
      After = "format-nix.service";
    };
    Service = {
      Type = "oneshot";
      Environment = "PATH=${pkgs.git}/bin:${pkgs.coreutils}/bin";
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
