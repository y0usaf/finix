{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.shell.zellij;

  # Import local generators
  generators = import ../../../../lib/generators {inherit lib;};
  toKDL = import ../../../../lib/generators/toKDL.nix {inherit lib;};

  # Import layouts
  musicLayout = import ./layouts/music.nix;

  # Base zellij configuration
  baseConfig = {
    hide_session_name = false;
    theme = "gruvbox-dark";
    default_shell = "zsh";

    # Optimization settings
    session_serialization = lib.mkIf cfg.performanceMode false;
    pane_viewport_serialization = lib.mkIf cfg.performanceMode false;
    scrollback_lines_to_serialize = lib.mkIf cfg.performanceMode 0;
  } // cfg.settings;
in {
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

        ".config/zellij/config-ide.kdl" = {
          clobber = true;
          text =
            toKDL.toKDL {} (baseConfig
              // {
                simplified_ui = true;
              })
            + "\n\n// Using default keybindings for now\n";
        };
      };
    };
  };
}