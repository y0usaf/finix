{
  config,
  pkgs,
  lib,
  ...
}: let
  formatScript = pkgs.writeShellScript "format-nix-watcher" ''
    set -euo pipefail

    WATCH_DIR="${config.home.services.formatNix.watchDirectory}"
    cd "$WATCH_DIR"

    echo "Watching $WATCH_DIR for .nix updates"

    ${pkgs.inotify-tools}/bin/inotifywait \
      -m \
      -r \
      -e close_write \
      --format '%w%f' \
      "$WATCH_DIR" | while read -r file; do
        case "$file" in
          *.nix)
            echo "Formatting $file"
            if ! ${pkgs.alejandra}/bin/alejandra "$file"; then
              echo "alejandra failed for $file" >&2
            fi
            ;;
        esac
      done
  '';
in {
  options.home.services.formatNix = {
    enable = lib.mkEnableOption "automatic Nix file formatting with alejandra";
    watchDirectory = lib.mkOption {
      type = lib.types.str;
      default = config.user.nixosConfigDirectory;
      description = "Directory to watch for Nix file changes";
    };
  };

  config = lib.mkIf config.home.services.formatNix.enable {
    environment.systemPackages = [pkgs.alejandra pkgs.inotify-tools];

    systemd.user.services.format-nix-watcher = {
      description = "Watch and format Nix files on change";
      after = ["graphical-session.target"];
      wantedBy = ["default.target"];

      serviceConfig = {
        Type = "simple";
        ExecStart = formatScript;
        Restart = "on-failure";
        RestartSec = "2";
      };
    };
  };
}
