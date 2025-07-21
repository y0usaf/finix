{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.nvide;
  username = "y0usaf";

  nvide-script = pkgs.writeShellScriptBin "nvide" ''
    #!/usr/bin/env bash

    # Nvide - NeoVim IDE with Neotree and split terminals
    # Inspired by Zide but using tmux + nvim instead of zellij

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

    # Check if tmux session already exists
    if tmux has-session -t "$session_name" 2>/dev/null; then
      echo "Session '$session_name' already exists. Attaching..."
      tmux attach-session -t "$session_name"
      exit 0
    fi

    # Create new tmux session
    echo "Creating nvide session: $session_name"
    echo "Working directory: $working_dir"

    # Start tmux session with nvim
    tmux new-session -d -s "$session_name" -c "$working_dir" -x 120 -y 30

    # Split the window: main pane (nvim) and right pane for terminals
    tmux split-window -h -t "$session_name" -c "$working_dir" -p 30

    # Split the right pane horizontally to create two terminal panes
    tmux split-window -v -t "$session_name:0.1" -c "$working_dir"

    # Start nvim in the main (left) pane with Neotree auto-open
    tmux send-keys -t "$session_name:0.0" "nvim ." Enter

    # Set pane titles
    tmux select-pane -t "$session_name:0.0" -T "NeoVim"
    tmux select-pane -t "$session_name:0.1" -T "Terminal 1"
    tmux select-pane -t "$session_name:0.2" -T "Terminal 2"

    # Focus on the nvim pane
    tmux select-pane -t "$session_name:0.0"

    # Attach to the session
    tmux attach-session -t "$session_name"
  '';
in {
  options.home.programs.nvide = {
    enable = lib.mkEnableOption "Nvide - NeoVim IDE environment";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      nvide-script
      pkgs.tmux
    ];

    programs.tmux = {
      enable = true;
      terminal = "screen-256color";
      keyMode = "vi";
      mouse = true;
      extraConfig = ''
        # Nvide specific tmux configuration
        set -g status-position top
        set -g status-style 'bg=#1e1e2e,fg=#cdd6f4'
        set -g status-left-length 20
        set -g status-right-length 50
        set -g status-left '#[fg=#89b4fa,bold]#{session_name} #[fg=#585b70]│ '
        set -g status-right '#[fg=#585b70]│ #[fg=#f9e2af]%Y-%m-%d #[fg=#89b4fa]%H:%M'

        # Pane borders
        set -g pane-border-style 'fg=#585b70'
        set -g pane-active-border-style 'fg=#89b4fa'

        # Window status
        set -g window-status-current-style 'fg=#89b4fa,bold'
        set -g window-status-style 'fg=#cdd6f4'

        # Enable pane titles
        set -g pane-border-status top
        set -g pane-border-format ' #{pane_title} '

        # Better pane navigation
        bind h select-pane -L
        bind j select-pane -D
        bind k select-pane -U
        bind l select-pane -R

        # Resize panes
        bind -r H resize-pane -L 5
        bind -r J resize-pane -D 5
        bind -r K resize-pane -U 5
        bind -r L resize-pane -R 5

        # Split panes with | and -
        bind | split-window -h -c "#{pane_current_path}"
        bind - split-window -v -c "#{pane_current_path}"

        # New window with current path
        bind c new-window -c "#{pane_current_path}"

        # Don't rename windows automatically
        set-option -g allow-rename off

        # Start windows and panes at 1
        set -g base-index 1
        set -g pane-base-index 1
        set-window-option -g pane-base-index 1
        set-option -g renumber-windows on
      '';
    };
  };
}
