{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.hyprlandConfigWatcher;
in {
  options.home.services.hyprlandConfigWatcher = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.home.ui.hyprland.enable or false;
      description = "Enable Hyprland configuration watcher service (auto-enabled when Hyprland is enabled)";
    };
    configPath = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.configDirectory}/hypr";
      description = "Path to the Hyprland configuration directory to watch";
    };
    reloadDelay = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Delay in seconds before reloading Hyprland after detecting changes";
    };
    startupDelay = lib.mkOption {
      type = lib.types.int;
      default = 5;
      description = "Delay in seconds before starting to watch (wait for Hyprland to be ready)";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.user.services."hyprland-config-watcher" = {
      description = "Watch Hyprland config directory for symlink changes and reload";
      script = ''
        set -x
        echo "Waiting ${toString cfg.startupDelay} seconds for Hyprland to be ready..."
        sleep ${toString cfg.startupDelay}
        reload_hyprland() {
          echo "Detected config change, reloading Hyprland in ${toString cfg.reloadDelay} seconds..."
          sleep ${toString cfg.reloadDelay}
          local instance_sig
          if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
            instance_sig="$HYPRLAND_INSTANCE_SIGNATURE"
          else
            instance_sig=$(ls /tmp/hypr/ 2>/dev/null | head -n 1)
          fi
          echo "Using Hyprland instance: $instance_sig"
          if command -v hyprctl >/dev/null 2>&1; then
            if [[ -n "$instance_sig" ]]; then
              export HYPRLAND_INSTANCE_SIGNATURE="$instance_sig"
            fi
            if hyprctl reload 2>&1; then
              echo "Hyprland reloaded successfully"
              return 0
            else
              echo "hyprctl reload failed"
            fi
          fi
          echo "Failed to reload Hyprland"
          return 1
        }
        if [[ ! -d "${cfg.configPath}" ]]; then
          echo "Config directory ${cfg.configPath} does not exist, creating it..."
          mkdir -p "${cfg.configPath}"
        fi
        echo "Starting to watch ${cfg.configPath} for changes..."
        inotifywait -m -r \
          --event modify \
          --event create \
          --event delete \
          --event move \
          --event attrib \
          --event delete_self \
          --event move_self \
          --format '%w%f %e %T' \
          --timefmt '%Y-%m-%d %H:%M:%S' \
          "${cfg.configPath}" 2>/dev/null | \
        while read -r file event timestamp; do
          echo "[$timestamp] Event: $event on $file"
          if pgrep -f "reload_hyprland" >/dev/null; then
            echo "Reload already in progress, skipping..."
            continue
          fi
          case "$event" in
            *MODIFY*|*CREATE*|*DELETE*|*MOVED*|*ATTRIB*)
              if [[ "$file" =~ \.(conf|json|toml)$ ]] || \
                 [[ "$(basename "$file")" == "hyprland.conf" ]] || \
                 [[ -L "$file" ]] || \
                 [[ "$event" =~ (ATTRIB|DELETE_SELF|MOVE_SELF) ]]; then
                echo "Triggering reload for: $file ($event)"
                reload_hyprland &
              fi
              ;;
          esac
        done
      '';
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = 5;
        Environment = [
          "XDG_RUNTIME_DIR=/run/user/${toString config.users.users.${config.user.name}.uid}"
          "WAYLAND_DISPLAY=wayland-1"
          "PATH=${lib.makeBinPath (with pkgs; [inotify-tools hyprland coreutils procps gnugrep util-linux])}:/run/current-system/sw/bin"
        ];
      };
      path = with pkgs; [
        inotify-tools
        hyprland
        coreutils
        procps
        gnugrep
        util-linux
      ];
      wantedBy = ["default.target"];
      after = ["default.target"];
      partOf = ["default.target"];
    };
  };
}
