###############################################################################
# Core Packages Module (Maid Version)
# Provides essential packages and default application configurations
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.core.packages;

  # Nvide script
  nvide-script = pkgs.writeShellScriptBin "nvide" ''
        #!/usr/bin/env bash

        # Nvide - NeoVim IDE with Neotree and split terminals
        # Using Zellij for terminal multiplexing

        HELP_TEXT="Usage: nvide [OPTIONS] [working_dir]

        Arguments:
          working_dir    Directory to open (default: current directory)

        Options:
          -h, --help     Show this help message
          -n, --name     Session name (default: basename of working directory)

        Description:
          Creates an IDE-like environment with:
          - Neotree file explorer on the left
          - NeoVim in the center
          - Two terminal panes split vertically on the right
        "

        show_help() {
          echo "$HELP_TEXT"
        }

        # Parse arguments
        session_name=""
        working_dir=""

        while [[ $# -gt 0 ]]; do
          case "$1" in
            -h|--help)
              show_help
              exit 0
              ;;
            -n|--name)
              if [[ -n "$2" && "$2" != -* ]]; then
                session_name="$2"
                shift 2
              else
                echo "Error: --name requires a value"
                exit 1
              fi
              ;;
            -*)
              echo "Unknown option: $1"
              echo "Use --help for usage information."
              exit 1
              ;;
            *)
              working_dir="$1"
              shift
              ;;
          esac
        done

        # Set defaults
        working_dir=''${working_dir:-$(pwd)}
        working_dir=$(cd "$working_dir" && pwd)  # Get absolute path
        session_name=''${session_name:-$(basename "$working_dir")}

        # Create nvide layout file
        layout_file="/tmp/nvide-layout-$session_name.kdl"
        cat > "$layout_file" << 'EOF'
    layout {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        pane {
            pane split_direction="horizontal" {
                pane size="70%" {
                    command "nvim"
                    args "."
                }
                pane split_direction="vertical" size="30%" {
                    pane
                    pane
                }
            }
        }
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    EOF

        # Check if session already exists
        if zellij list-sessions 2>/dev/null | grep -q "^$session_name$"; then
          echo "Session '$session_name' already exists. Attaching..."
          zellij attach "$session_name"
          exit 0
        fi

        # Create new zellij session
        echo "Creating nvide session: $session_name"
        echo "Working directory: $working_dir"

        # Start zellij session with custom layout
        cd "$working_dir"
        zellij --session "$session_name" --layout "$layout_file"
  '';

  # Base packages all users should have
  basePackages = with pkgs; [
    # Essential CLI tools
    git
    curl
    wget
    cachix
    unzip
    bash
    lsd
    alejandra
    tree
    bottom
    psmisc
    kitty
    # System interaction
    dconf
    lm_sensors
    networkmanager
    # IDE tools
    nvide-script
  ];
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.core.packages = {
    enable = lib.mkEnableOption "core packages and base system tools";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid.packages = basePackages ++ cfg.extraPackages;
  };
}
