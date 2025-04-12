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
    MAX_RETRIES=10
    RETRY_DELAY=3

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
          --restart unless-stopped \
          "$DOCKER_IMAGE"
      fi

      echo "Bambu Studio container started."
      echo "Waiting for web interface to become available at: http://localhost:$PORT"

      # Wait for container to be fully up and running
      local retries=0
      while [ $retries -lt $MAX_RETRIES ]; do
        if curl -s -o /dev/null -m 1 http://localhost:$PORT; then
          echo "Web interface is now available!"
          return 0
        fi
        echo "Waiting for web interface to initialize ($(($retries + 1))/$MAX_RETRIES)..."
        sleep $RETRY_DELAY
        retries=$((retries + 1))
      done

      echo "Warning: Web interface didn't respond in the expected time."
      echo "The container might still be initializing. Try manually accessing:"
      echo "  http://localhost:$PORT"
      echo "or check container logs with:"
      echo "  bambu-studio logs"
    }

    function stop_container() {
      echo "Stopping Bambu Studio container..."
      if ! is_container_running; then
        echo "Container is not running."
        return
      fi
      docker stop "$CONTAINER_NAME"
      echo "Bambu Studio container stopped."
    }

    function remove_container() {
      if container_exists; then
        if is_container_running; then
          echo "Stopping Bambu Studio container first..."
          docker stop "$CONTAINER_NAME"
        fi
        echo "Removing Bambu Studio container..."
        docker rm "$CONTAINER_NAME"
        echo "Bambu Studio container removed."
      else
        echo "Container doesn't exist, nothing to remove."
      fi
    }

    function show_status() {
      if container_exists; then
        if is_container_running; then
          echo "Bambu Studio container is running."
          # Check if web interface is responding
          if curl -s -o /dev/null -m 1 http://localhost:$PORT; then
            echo "Web interface is accessible at: http://localhost:$PORT"
          else
            echo "Container is running, but web interface is not responding at: http://localhost:$PORT"
            echo "The interface might still be initializing. Check logs with: bambu-studio logs"
          fi

          # Show container details
          echo "------------------------------------"
          echo "Container details:"
          docker inspect --format "Created: {{.Created}}, Status: {{.State.Status}}, Started: {{.State.StartedAt}}" "$CONTAINER_NAME"
          echo "Port mappings:"
          docker port "$CONTAINER_NAME"
          echo "------------------------------------"
        else
          echo "Bambu Studio container exists but is not running."
          echo "Start it with: bambu-studio start"
        fi
      else
        echo "Bambu Studio container does not exist."
        echo "Create and start it with: bambu-studio start"
      fi
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

      # Check container state
      if ! container_exists; then
        echo "Container doesn't exist. No troubleshooting possible."
        return
      fi

      echo "Container state:"
      docker inspect --format "Status: {{.State.Status}}, Running: {{.State.Running}}, Error: {{.State.Error}}" "$CONTAINER_NAME"

      # Check logs for errors
      echo "Recent logs (last 20 lines):"
      docker logs --tail 20 "$CONTAINER_NAME"

      # Check network
      echo "Network connection test:"
      if is_container_running; then
        echo "Port mappings:"
        docker port "$CONTAINER_NAME"

        # Test port connectivity
        echo "Testing connection to port $PORT:"
        if curl -s -o /dev/null -m 1 http://localhost:$PORT; then
          echo "Port $PORT is reachable!"
        else
          echo "Cannot connect to port $PORT - the service might still be starting up"
          echo "or there might be a networking issue."
        fi
      else
        echo "Container is not running. Start it first with: bambu-studio start"
      fi

      echo "------------------------------------"
      echo "Troubleshooting complete. If you still have issues:"
      echo "1. Try restarting the container: bambu-studio restart"
      echo "2. Make sure no other service is using port $PORT"
      echo "3. Check your firewall settings"
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
      echo "Commands:"
      echo "  start       Start the Bambu Studio container"
      echo "  stop        Stop the Bambu Studio container"
      echo "  restart     Restart the Bambu Studio container"
      echo "  status      Show container status"
      echo "  logs        Show container logs"
      echo "  logs-f      Follow container logs"
      echo "  troubleshoot Check and diagnose common issues"
      echo "  remove      Remove the Bambu Studio container"
      echo "  open        Open the web interface in browser"
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
      open)
        if ! is_container_running; then
          echo "Bambu Studio container is not running. Starting it now..."
          start_container
        else
          # Check if web interface is responding
          if ! curl -s -o /dev/null -m 1 http://localhost:$PORT; then
            echo "Web interface is not yet responding. It might still be initializing."
            echo "Waiting a moment for it to become available..."
            sleep 5
          fi
        fi

        echo "Opening Bambu Studio web interface in your browser..."
        if xdg-open "http://localhost:$PORT" &> /dev/null; then
          echo "Browser opened successfully."
        else
          echo "Failed to open browser. Try accessing this URL manually:"
          echo "  http://localhost:$PORT"
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
