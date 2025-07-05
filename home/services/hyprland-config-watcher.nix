###############################################################################
# Hyprland Configuration Watcher Service
# Watches for changes to Hyprland config symlinks and reloads Hyprland
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.home.services.hyprlandConfigWatcher;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.services.hyprlandConfigWatcher = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.home.ui.hyprland.enable or false;
      description = "Enable Hyprland configuration watcher service (auto-enabled when Hyprland is enabled)";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/y0usaf/.config/hypr";
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

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      systemd.services."hyprland-config-watcher" = {
        description = "Watch Hyprland config directory for symlink changes and reload";
        script = ''
          # Enable debug output for logging
          set -x

          # Wait for Hyprland to be ready
          echo "Waiting ${toString cfg.startupDelay} seconds for Hyprland to be ready..."
          sleep ${toString cfg.startupDelay}

          # Function to reload Hyprland
          reload_hyprland() {
            echo "Detected config change, reloading Hyprland in ${toString cfg.reloadDelay} seconds..."
            sleep ${toString cfg.reloadDelay}

            # Get Hyprland instance signature
            local instance_sig
            if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
              instance_sig="$HYPRLAND_INSTANCE_SIGNATURE"
            else
              # Try to auto-detect the instance
              instance_sig=$(ls /tmp/hypr/ 2>/dev/null | head -n 1)
            fi

            echo "Using Hyprland instance: $instance_sig"

            # Try to reload via hyprctl
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

          # Ensure config directory exists and is readable
          if [[ ! -d "${cfg.configPath}" ]]; then
            echo "Config directory ${cfg.configPath} does not exist, creating it..."
            mkdir -p "${cfg.configPath}"
          fi

          # Watch for changes to the Hyprland config directory
          echo "Starting to watch ${cfg.configPath} for changes..."

          # Use inotifywait to monitor for file system events
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

            # Debounce rapid changes (skip if another reload is already running)
            if pgrep -f "reload_hyprland" >/dev/null; then
              echo "Reload already in progress, skipping..."
              continue
            fi

            # Filter for relevant events and files
            case "$event" in
              *MODIFY*|*CREATE*|*DELETE*|*MOVED*|*ATTRIB*)
                # Check if it's a relevant config file
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
          User = "y0usaf";
          Environment = [
            "XDG_RUNTIME_DIR=/run/user/1000"
            "WAYLAND_DISPLAY=wayland-1"
            "PATH=/run/current-system/sw/bin"
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
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
      };
    };
  };
}
