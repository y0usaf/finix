{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.core.packages;
  nvide-script = pkgs.writeShellScriptBin "nvide" ''
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
        working_dir=''${working_dir:-$(pwd)}
        working_dir=$(cd "$working_dir" && pwd)
        session_name=''${session_name:-$(basename "$working_dir")}
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
        if zellij list-sessions 2>/dev/null | grep -q "^$session_name$"; then
          echo "Session '$session_name' already exists. Attaching..."
          zellij attach "$session_name"
          exit 0
        fi
        echo "Creating nvide session: $session_name"
        echo "Working directory: $working_dir"
        cd "$working_dir"
        zellij --session "$session_name" --layout "$layout_file"
  '';
  basePackages = with pkgs; [
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
    dconf
    lm_sensors
    networkmanager
    nvide-script
  ];
in {
  options.home.core.packages = {
    enable = lib.mkEnableOption "core packages and base system tools";
    extraPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      description = "Additional packages to install";
    };
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.packages = basePackages ++ cfg.extraPackages;
  };
}
