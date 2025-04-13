###############################################################################
# Bambu Studio Module
# Provides Bambu Studio 3D printer slicer and control software
###############################################################################
{
  config,
  pkgs,
  lib,
  host,
  ...
}: let
  cfg = config.cfg.programs.bambustudio;

  # Default data directory
  defaultDataDir = "${config.home.homeDirectory}/.local/share/bambustudio";

  # Helper script for managing the Bambu Studio container
  bambuStudioScript = pkgs.writeShellScriptBin "bambu-studio" ''
        #!/usr/bin/env bash
        set -eo pipefail

        # Constants
        CONTAINER_NAME="bambustudio"
        DATA_DIR="${cfg.dataDir}"
        PORT="${toString cfg.port}"
        DOCKER_IMAGE="lscr.io/linuxserver/bambustudio:latest"
        CHECK_INTERVAL=3        # How often to check for service availability
        NOTIFY_ENABLED=true     # Whether to use desktop notifications
        AUTO_NOTIFY=${
      if cfg.autoNotify
      then "true"
      else "false"
    }

        # Functions
        function check_docker() {
          if ! command -v docker &> /dev/null; then
            echo "Error: Docker is not installed or not in PATH"
            exit 1
          fi

          # Check if user can run docker without sudo
          if ! docker info &>/dev/null; then
            echo "Warning: You don't have permission to use Docker without sudo."
            echo "Consider adding your user to the docker group:"
            echo "  sudo usermod -aG docker $USER"
            echo "You'll need to log out and back in for this to take effect."
            echo "For now, try running: sudo bambu-studio $1"
            exit 1
          fi
        }

        function is_container_running() {
          docker ps --filter "name=^/$CONTAINER_NAME$" --format '{{.Names}}' | grep -q "$CONTAINER_NAME" 2>/dev/null
        }

        function container_exists() {
          docker ps -a --filter "name=^/$CONTAINER_NAME$" --format '{{.Names}}' | grep -q "$CONTAINER_NAME" 2>/dev/null
        }

        function send_notification() {
          if [ "$NOTIFY_ENABLED" = true ] && command -v notify-send &> /dev/null; then
            notify-send -a "Bambu Studio" "$@"
          fi
        }

        function is_service_ready() {
          curl -s -o /dev/null -m 2 "http://localhost:$PORT" && return 0 || return 1
        }

        function monitor_until_ready() {
          local quiet=$1
          local start_time
          local end_time
          local duration

          start_time=$(date +%s)

          while true; do
            if is_service_ready; then
              end_time=$(date +%s)
              duration=$((end_time - start_time))

              if [ "$quiet" != "quiet" ]; then
                echo ""
                echo "✅ Bambu Studio web interface is now READY!"
                echo "   Took $duration seconds to initialize"
                echo "   Access at: http://localhost:$PORT"
              fi

              send_notification "Bambu Studio Ready" "Web interface is now available at:\nhttp://localhost:$PORT\n\nTook $duration seconds to initialize."
              return 0
            fi

            # Check if container is still running
            if ! is_container_running; then
              if [ "$quiet" != "quiet" ]; then
                echo "❌ Container stopped unexpectedly"
              fi
              send_notification "Bambu Studio Error" "Container stopped unexpectedly"
              return 1
            fi

            if [ "$quiet" != "quiet" ]; then
              echo -n "."
            fi
            sleep $CHECK_INTERVAL
          done
        }

        function start_container() {
          echo "Starting Bambu Studio container..."

          if container_exists; then
            # Container exists, just start it
            docker start "$CONTAINER_NAME"
          else
            # Create and start container
            docker run -d \
              --name="$CONTAINER_NAME" \
              -e PUID=$(id -u) \
              -e PGID=$(id -g) \
              -e TZ="$(timedatectl show --property=Timezone --value)" \
              -p "$PORT:6080" \
              -v "$DATA_DIR:/config" \
              --security-opt seccomp=unconfined `# Better container security compatibility` \
              --shm-size=1gb `# Increase shared memory size for browser performance` \
              --restart unless-stopped \
              "$DOCKER_IMAGE"
          fi

          echo "✅ Bambu Studio container started."

          # Explain why it takes time
          cat << EOF
    📋 About Bambu Studio Initialization:
       - The container needs to start up a VNC server and web interface
       - First-time startup can take 1-2 minutes (faster on subsequent runs)
       - You can:
         1. Wait here with 'bambu-studio watch' (recommended)
         2. Get notified with 'bambu-studio notify' (runs in background)
         3. Check status later with 'bambu-studio status'
    EOF

          # Start background monitoring if auto_notify is enabled
          if [ "$AUTO_NOTIFY" = "true" ]; then
            echo "🔔 Will notify you when ready (monitoring in background)"
            $0 notify &>/dev/null &
            disown
          else
            echo ""
            echo "⚡ For continuous monitoring: bambu-studio watch"
            echo "🔍 To check status later:     bambu-studio status"
            echo "🌐 Web interface URL:         http://localhost:$PORT"
          fi
        }

        function stop_container() {
          echo "Stopping Bambu Studio container..."
          if ! is_container_running; then
            echo "Container is not running."
            return
          fi
          docker stop "$CONTAINER_NAME"
          echo "✅ Bambu Studio container stopped."
        }

        function remove_container() {
          if container_exists; then
            if is_container_running; then
              echo "Stopping Bambu Studio container first..."
              docker stop "$CONTAINER_NAME"
            fi
            echo "Removing Bambu Studio container..."
            docker rm "$CONTAINER_NAME"
            echo "✅ Bambu Studio container removed."
          else
            echo "Container doesn't exist, nothing to remove."
          fi
        }

        function show_status() {
          if container_exists; then
            if is_container_running; then
              echo "📊 Bambu Studio Container Status:"
              echo "--------------------------------"
              # Check if web interface is responding
              if is_service_ready; then
                echo "✅ Container: RUNNING"
                echo "✅ Web Interface: READY at http://localhost:$PORT"
              else
                echo "✅ Container: RUNNING"
                echo "⏳ Web Interface: INITIALIZING... not yet available"
                echo ""
                echo "Wait for initialization with: bambu-studio watch"
                echo "Get notified when ready:      bambu-studio notify"
              fi

              # Show container details
              echo ""
              echo "Container Info:"
              docker inspect --format "Created: {{.Created}}, Started: {{.State.StartedAt}}" "$CONTAINER_NAME"
              echo "Uptime: $(docker ps --filter "name=$CONTAINER_NAME" --format "{{.RunningFor}}")"
              echo "Port mappings: $(docker port "$CONTAINER_NAME")"
            else
              echo "❌ Bambu Studio container exists but is NOT RUNNING."
              echo "Start it with: bambu-studio start"
            fi
          else
            echo "❌ Bambu Studio container does not exist."
            echo "Create and start it with: bambu-studio start"
          fi
        }

        function watch_container() {
          if ! is_container_running; then
            echo "Container is not running. Starting it first..."
            start_container
          fi

          echo "Watching for Bambu Studio web interface to come online..."
          echo -n "Waiting for http://localhost:$PORT"

          monitor_until_ready

          if [ $? -eq 0 ]; then
            echo ""
            echo "You can now access Bambu Studio at: http://localhost:$PORT"
          else
            echo ""
            echo "Failed to detect web interface. Check logs with: bambu-studio logs"
          fi
        }

        function background_notify() {
          if ! is_container_running; then
            echo "Container is not running. Start it first with: bambu-studio start"
            exit 1
          fi

          if is_service_ready; then
            echo "Web interface is already available at: http://localhost:$PORT"
            exit 0
          fi

          echo "Will send a notification when Bambu Studio is ready"
          echo "This command will run in the background - you can close this terminal"

          # Exit success immediately but continue running in background
          (monitor_until_ready "quiet" &)
          exit 0
        }

        function troubleshoot() {
          echo "Troubleshooting Bambu Studio container..."
          echo "------------------------------------"

          # Check if Docker is running
          if ! systemctl is-active --quiet docker; then
            echo "Docker service is not running. Start it with:"
            echo "  sudo systemctl start docker"
            return
          fi

          # Check for available memory
          echo "System memory status:"
          free -h

          # Check disk space in data directory
          echo "Disk space in data directory:"
          df -h "$DATA_DIR" | grep -v Filesystem

          # Check for firewall issues
          echo "Checking if firewall might be blocking connections:"
          if command -v firewall-cmd &> /dev/null; then
            echo "Firewall status: $(firewall-cmd --state 2>/dev/null || echo 'unknown')"
          elif command -v ufw &> /dev/null; then
            echo "UFW status: $(ufw status | grep Status || echo 'unknown')"
          else
            echo "No recognized firewall found"
          fi

          # Check container state
          if ! container_exists; then
            echo "Container doesn't exist. No troubleshooting possible."
            return
          fi

          echo "Container state:"
          docker inspect --format "Status: {{.State.Status}}, Running: {{.State.Running}}, Error: {{.State.Error}}" "$CONTAINER_NAME"

          # Check Docker events
          echo "Recent Docker events for this container:"
          docker events --filter container=$CONTAINER_NAME --since 10m --until 0m 2>/dev/null || echo "No recent events found"

          # Check logs for errors
          echo "Recent logs (last 20 lines):"
          docker logs --tail 20 "$CONTAINER_NAME"

          # Check if noVNC is running inside container
          echo "Checking noVNC processes inside container:"
          docker exec -it $CONTAINER_NAME ps aux | grep -E 'novnc|vncserver|Xvnc' 2>/dev/null || echo "Could not check processes"

          # Check network
          echo "Network connection test:"
          if is_container_running; then
            echo "Port mappings:"
            docker port "$CONTAINER_NAME"

            # Test port connectivity
            echo "Testing connection to port $PORT:"
            if is_service_ready; then
              echo "Port $PORT is reachable!"
            else
              echo "Cannot connect to port $PORT - the service might still be starting up"
              echo "or there might be a networking issue."

              # Try netstat to see if anything is listening
              echo "Checking if any process is listening on port $PORT:"
              netstat -tuln | grep $PORT || echo "No process found listening on port $PORT"
            fi
          else
            echo "Container is not running. Start it first with: bambu-studio start"
          fi

          echo "------------------------------------"
          echo "Troubleshooting complete. If you still have issues:"
          echo "1. Try restarting the container: bambu-studio restart"
          echo "2. Try the watch command to monitor startup: bambu-studio watch"
          echo "3. Make sure no other service is using port $PORT"
          echo "4. Check your firewall settings"
          echo "5. Try rebuilding the container: bambu-studio remove && bambu-studio start"
        }

        function show_logs() {
          if container_exists; then
            docker logs $([[ "$1" == "--follow" ]] && echo "-f") "$CONTAINER_NAME"
          else
            echo "Container doesn't exist, no logs to show."
          fi
        }

        function show_usage() {
          echo "Bambu Studio Container Manager"
          echo
          echo "Usage: bambu-studio COMMAND"
          echo
          echo "Container Commands:"
          echo "  start       Start the Bambu Studio container"
          echo "  stop        Stop the Bambu Studio container"
          echo "  restart     Restart the Bambu Studio container"
          echo "  remove      Remove the Bambu Studio container"
          echo
          echo "Status Commands:"
          echo "  status      Show container status"
          echo "  logs        Show container logs"
          echo "  logs-f      Follow container logs"
          echo "  troubleshoot Check and diagnose common issues"
          echo
          echo "Access Commands:"
          echo "  watch       Wait and watch until web interface is ready"
          echo "  notify      Get desktop notification when ready (background)"
          echo "  open        Open the web interface in browser"
          echo
          echo "Other Commands:"
          echo "  help        Show this help message"
          echo
        }

        # Skip Docker check for certain commands
        SKIP_DOCKER_CHECK=0
        if [[ "$1" == "help" || "$1" == "" ]]; then
          SKIP_DOCKER_CHECK=1
        fi

        # Main execution
        if [[ $SKIP_DOCKER_CHECK -eq 0 ]]; then
          check_docker "$1"
        fi

        case "$1" in
          start)
            start_container
            ;;
          stop)
            stop_container
            ;;
          restart)
            if is_container_running; then
              stop_container
            fi
            start_container
            ;;
          remove)
            remove_container
            ;;
          status)
            show_status
            ;;
          logs)
            show_logs
            ;;
          logs-f)
            show_logs --follow
            ;;
          troubleshoot)
            troubleshoot
            ;;
          watch)
            watch_container
            ;;
          notify)
            background_notify
            ;;
          open)
            if ! is_container_running; then
              echo "Bambu Studio container is not running. Starting it first..."
              start_container
              echo "Use 'bambu-studio watch' to wait for it to be ready"
            elif ! is_service_ready; then
              echo "Web interface is not yet ready. Monitoring until available..."
              watch_container
            else
              echo "Opening Bambu Studio web interface in your browser..."
              if xdg-open "http://localhost:$PORT" &> /dev/null; then
                echo "Browser opened successfully."
              else
                echo "Failed to open browser. Try accessing this URL manually:"
                echo "  http://localhost:$PORT"
              fi
            fi
            ;;
          help|*)
            show_usage
            ;;
        esac
  '';
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.programs.bambustudio = {
    enable = lib.mkEnableOption "Bambu Studio 3D printing slicer";

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = defaultDataDir;
      description = "Directory to store Bambu Studio configuration and data";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6080;
      description = "Port to expose the Bambu Studio web interface on";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to automatically start the Bambu Studio container on login";
    };

    autoNotify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically notify when the web interface is ready";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      # Main management script
      bambuStudioScript

      # Dependencies
      docker
      curl # For checking web interface availability
      libnotify # For desktop notifications
    ];

    ###########################################################################
    # Activation Script
    ###########################################################################
    home.activation.setupBambuStudio = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Create data directory if it doesn't exist
      $DRY_RUN_CMD mkdir -p "${cfg.dataDir}"

      # Setup the container if autoStart is enabled
      ${lib.optionalString cfg.autoStart ''
        $DRY_RUN_CMD ${bambuStudioScript}/bin/bambu-studio start
      ''}
    '';

    ###########################################################################
    # Desktop Integration
    ###########################################################################
    xdg.desktopEntries.bambustudio = {
      name = "Bambu Studio";
      genericName = "3D Printing Software";
      comment = "3D printing slicer and control software for Bambu Lab printers";
      exec = "${bambuStudioScript}/bin/bambu-studio open";
      terminal = false;
      icon = "${pkgs.fetchurl {
        url = "https://github.com/bambulab/BambuStudio/raw/master/resources/images/BambuStudioTitle.ico";
        hash = "sha256-PvdctxmsYL9hL3BetdY8Flwf3T8jEjH++zYEVb4Dqg8=";
      }}";
      categories = ["Graphics" "3DGraphics"];
    };
  };
}
