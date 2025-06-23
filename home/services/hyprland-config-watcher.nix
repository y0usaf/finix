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
      default = 1;
      description = "Delay in seconds before reloading Hyprland after detecting changes";
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

          # Function to reload Hyprland
          reload_hyprland() {
            echo "Detected config change, reloading Hyprland in ${toString cfg.reloadDelay} seconds..."
            sleep ${toString cfg.reloadDelay}

            # Try to reload via hyprctl first
            if command -v hyprctl >/dev/null 2>&1; then
              if hyprctl reload 2>/dev/null; then
                echo "Hyprland reloaded successfully via hyprctl"
                return 0
              else
                echo "hyprctl reload failed, trying dispatch reload"
                if hyprctl dispatch exec "hyprctl reload" 2>/dev/null; then
                  echo "Hyprland reloaded successfully via dispatch"
                  return 0
                fi
              fi
            fi

            echo "Failed to reload Hyprland - hyprctl not available or failed"
            return 1
          }

          # Watch for changes to the Hyprland config directory
          # Using inotify to watch for symlink changes, file modifications, and moves
          echo "Starting to watch ${cfg.configPath} for changes..."

          inotifywait -m -r \
            --event modify \
            --event create \
            --event delete \
            --event move \
            --event attrib \
            --format '%w%f %e' \
            "${cfg.configPath}" 2>/dev/null | \
          while read -r file event; do
            echo "Detected event: $event on $file"

            # Filter for relevant events (symlink changes, config file modifications)
            case "$event" in
              *MODIFY*|*CREATE*|*DELETE*|*MOVED*|*ATTRIB*)
                # Check if it's a config file or symlink change
                if [[ "$file" =~ \.(conf|json|toml)$ ]] || [[ -L "$file" ]] || [[ "$event" =~ ATTRIB ]]; then
                  reload_hyprland &
                fi
                ;;
            esac
          done
        '';

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 3;
          User = "y0usaf";
          Environment = [
            "HYPRLAND_INSTANCE_SIGNATURE="
            "XDG_RUNTIME_DIR=/run/user/1000"
          ];
        };

        path = with pkgs; [
          inotify-tools
          hyprland
          coreutils
          procps
        ];

        wantedBy = ["graphical-session.target"];
        after = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
      };
    };
  };
}
