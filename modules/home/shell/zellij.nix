{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;
  ideLayout = import ./zellij-ide.nix {inherit lib config;};
  toKDL = import ../../../lib/generators/toKDL.nix {inherit lib;};

  # Base zellij configuration
  baseConfig = {
    hide_session_name = false;
    on_force_close = "quit";
    pane_frames = true;
    rounded_corners = true;
    session_serialization = false;
    show_startup_tips = false;
  };

  # Music layout configuration
  musicLayout = {
    layout = {
      _args = ["alias=music"];
      default_tab_template = {
        _children = [
          {
            pane = {
              _args = ["size=1" "borderless=true"];
              plugin = {
                _args = ["location=zellij:tab-bar"];
              };
            };
          }
          {
            children = {};
          }
          {
            pane = {
              _args = ["size=2" "borderless=true"];
              plugin = {
                _args = ["location=zellij:status-bar"];
              };
            };
          }
        ];
      };
      tab = {
        _args = ["name=Music"];
        pane = {
          _args = ["split_direction=vertical"];
          _children = [
            {
              pane = {
                _args = ["command=cmus"];
              };
            }
            {
              pane = {
                _args = ["command=cava"];
              };
            }
          ];
        };
      };
    };
  };
in {
  options.home.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Automatically start zellij when opening zsh";
    };
    fastStartup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Optimize configuration for faster startup times";
    };
    layouts = {
      ide = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "IDE layout configuration";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        zellij
      ];
      files = {
        ".config/zellij/config.kdl" = {
          clobber = true;
          text =
            toKDL.toKDL {} (baseConfig
              // {
                simplified_ui = false;
              })
            + "\n\n// Using default keybindings for now\n";
        };
        ".config/zellij/layouts/music.kdl" = {
          clobber = true;
          text = toKDL.toKDL {} musicLayout;
        };

        ".config/zellij/layouts/ide.kdl" = {
          clobber = true;
          text = ideLayout.home.shell.zellij.layouts.ide;
        };
        ".config/zellij/config-ide.kdl" = {
          clobber = true;
          text =
            toKDL.toKDL {} (baseConfig
              // {
                simplified_ui = true;
              })
            + "\n\n// Using default keybindings for now\n";
        };
        ".config/zsh/aliases/zellij.zsh" = {
          clobber = true;
          text = lib.optionalString cfg.autoStart ''
            # Auto-start zellij if not already running and not in special environments
            # Skip for login TTYs (tty1-tty6) and SSH connections
            if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]; then
                # Check if we're on a login TTY
                if [[ "$TTY" =~ ^/dev/tty[0-9]+$ ]]; then
                    # We're on a login TTY, don't auto-start
                    :
                elif [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
                    # We're in a graphical terminal, safe to auto-start
                    exec zellij
                fi
            fi
          '';
        };
      };
    };
  };
}
