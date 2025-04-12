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

    # Functions
    function check_docker() {
      if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed or not in PATH"
        exit 1
      fi
    }

    function is_container_running() {
      docker ps --filter "name=^/$CONTAINER_NAME$" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"
    }

    function container_exists() {
      docker ps -a --filter "name=^/$CONTAINER_NAME$" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"
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
      echo "Access the web interface at: http://localhost:$PORT"
    }

    function stop_container() {
      echo "Stopping Bambu Studio container..."
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
          echo "Access the web interface at: http://localhost:$PORT"
        else
          echo "Bambu Studio container exists but is not running."
        fi
      else
        echo "Bambu Studio container does not exist."
      fi
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
      echo "  start      Start the Bambu Studio container"
      echo "  stop       Stop the Bambu Studio container"
      echo "  restart    Restart the Bambu Studio container"
      echo "  remove     Remove the Bambu Studio container"
      echo "  status     Show container status"
      echo "  logs       Show container logs"
      echo "  logs-f     Follow container logs"
      echo "  help       Show this help message"
      echo
    }

    # Main execution
    check_docker

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
      open)
        if ! is_container_running; then
          echo "Bambu Studio container is not running. Starting it now..."
          start_container
          # Give it a moment to initialize
          sleep 3
        fi
        echo "Opening Bambu Studio web interface in your browser..."
        xdg-open "http://localhost:$PORT" &> /dev/null || echo "Failed to open browser"
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
