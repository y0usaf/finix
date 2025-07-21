###############################################################################
# Zellij Terminal Multiplexer Module (Maid Version)
# Configures the Zellij terminal multiplexer with custom themes and layouts
# - Custom theme configuration
# - Music layout for cmus and cava
# - Convenient shell aliases
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;
  # ZSH configuration for zellij auto-start
  zshConfig = {
    zellij = {
      enable = false;
    };
  };
  # Import IDE layout
  ideLayout = import ./zellij-ide.nix { inherit lib; };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
    layouts = {
      ide = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "IDE layout configuration";
      };
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
      ###########################################################################
      # Packages
      ###########################################################################
      packages = with pkgs; [
        zellij
      ];

      ###########################################################################
      # File Configuration
      ###########################################################################
      file = {
        ###########################################################################
        # Configuration Files
        ###########################################################################
        xdg_config = {
          # Main Zellij configuration
          "zellij/config.kdl".text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui false
          '';

          # Music layout
          "zellij/layouts/music.kdl".text = ''
            layout alias="music" {
                default_tab_template {
                    pane size=1 borderless=true {
                        plugin location="zellij:tab-bar"
                    }
                    children
                    pane size=2 borderless=true {
                        plugin location="zellij:status-bar"
                    }
                }

                tab name="Music" {
                    pane split_direction="vertical" {
                        pane command="cmus"
                        pane command="cava"
                    }
                }
            }
          '';

          # IDE layout
          "zellij/layouts/ide.kdl".text = ideLayout.home.shell.zellij.layouts.ide;

          # IDE config with simplified UI
          "zellij/config-ide.kdl".text = ''
            hide_session_name false
            on_force_close "quit"
            pane_frames true
            rounded_corners true
            session_serialization false
            show_startup_tips false
            simplified_ui true
          '';



          # Note: Shell configuration (zshrc, zlogout) should be handled by shell modules
          # Keeping only zellij-specific config files here
        };

        ###########################################################################
        # Shell Integration - Auto-start Zellij
        ###########################################################################
        home."{{xdg_config_home}}/zsh/.zshrc".text = lib.mkBefore (lib.optionalString zshConfig.zellij.enable ''
          # ----------------------------
          # Zellij Auto-start
          # ----------------------------
          # Automatically start Zellij if not already in a session
          # Skip if in nvim, vscode, or SSH connection
          if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && "$TERM_PROGRAM" != "vscode" && -z "$NVIM" ]]; then
              exec zellij
          fi

        '');
      };
    };
  };
}
