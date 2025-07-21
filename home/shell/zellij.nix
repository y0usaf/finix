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
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.shell.zellij = {
    enable = lib.mkEnableOption "zellij terminal multiplexer";
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
            theme "custom"
            themes {
            	custom {
            		bg "#282828"
            		black "#282828"
            		blue "#458588"
            		cyan "#689d6a"
            		exit_code_error {
            			base "#cc241d"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#cc241d"
            		}
            		exit_code_success {
            			base "#98971a"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#98971a"
            		}
            		fg "#ebdbb2"
            		frame_highlight {
            			base "#d79921"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#d79921"
            		}
            		frame_selected {
            			base "#458588"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#458588"
            		}
            		green "#98971a"
            		list_selected {
            			base "#ebdbb2"
            			bg "#3c3836"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		list_unselected {
            			base "#ebdbb2"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		magenta "#b16286"
            		multiplayer_user_colors "#cc241d" "#98971a" "#d79921" "#458588" "#b16286" "#689d6a" "#ebdbb2" "#d65d0e" "#a89984" "#3c3836"
            		orange "#d65d0e"
            		red "#cc241d"
            		ribbon_selected {
            			base "#ebdbb2"
            			bg "#458588"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#ebdbb2"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		ribbon_unselected {
            			base "#ebdbb2"
            			bg "#3c3836"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#ebdbb2"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#a89984"
            		}
            		table_cell_selected {
            			base "#ebdbb2"
            			bg "#3c3836"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		table_cell_unselected {
            			base "#ebdbb2"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		table_title {
            			base "#ebdbb2"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		text_selected {
            			base "#ebdbb2"
            			bg "#3c3836"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		text_unselected {
            			base "#ebdbb2"
            			bg "#282828"
            			emphasis_0 "#cc241d"
            			emphasis_1 "#98971a"
            			emphasis_2 "#689d6a"
            			emphasis_3 "#d65d0e"
            			fg "#ebdbb2"
            		}
            		white "#ebdbb2"
            		yellow "#d79921"
            	}
            }
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
          "zellij/layouts/ide.kdl".text = ''
            layout {
                pane size=1 borderless=true {
                    plugin location="zellij:tab-bar"
                }
                pane split_direction="horizontal" {
                    pane size="20%" {
                        command "nvim"
                        args "+Neotree"
                    }
                    pane size="50%" {
                        command "nvim"
                        args "."
                    }
                    pane split_direction="vertical" size="30%" {
                        pane
                        pane
                    }
                }
                pane size=2 borderless=true {
                    plugin location="zellij:status-bar"
                }
            }
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
