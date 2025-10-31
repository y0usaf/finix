{
  config,
  lib,
  pkgs,
  inputs,
  genLib,
  ...
}: let
  cfg = config.user.shell.zellij;

  # Base configuration as structured data
  baseConfig =
    {
      hide_session_name = false;
      copy_on_select = true;
      show_startup_tips = false;
      on_force_close = "quit";
      session_serialization = false;
      pane_frames = true;
    }
    // lib.optionalAttrs cfg.zjstatus.enable {
      default_layout = "zjstatus";
    }
    // cfg.settings;

  zjstatusHintsConfig = let
    c = config.user.shell.zellij;
  in
    lib.optionalString (c.zjstatusHints.enable or false) ''
      plugins {
        zjstatus-hints location="file:${inputs.zjstatus-hints.packages.${pkgs.system}.default}/bin/zjstatus-hints.wasm" {
          max_length ${toString (c.zjstatusHints.maxLength or 0)}
          pipe_name "${c.zjstatusHints.pipeName or "zjstatus_hints"}"
        }
      }

      load_plugins {
        zjstatus-hints
      }
    '';
in {
  config = lib.mkIf cfg.enable {
    home-manager.users.y0usaf =
      {
        programs.zellij = {
          enable = true;
          inherit (cfg) package;
        };

        home.file.".config/zellij/config.kdl" = {
          text =
            genLib.toKDL baseConfig
            + "\n\n// Using default keybindings for now\n"
            + zjstatusHintsConfig
            + cfg.themeConfig;
        };
      }
      // lib.optionalAttrs cfg.autoStart {
        home.file.".config/zsh/init-zellij.zsh" = {
          text = ''
            # Auto-start zellij if not already in a session
            if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && -z "$TMUX" ]]; then
              exec zellij
            fi
          '';
        };

        programs.zsh.initContent = lib.mkAfter ''
          [[ -f "$XDG_CONFIG_HOME/zsh/init-zellij.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/init-zellij.zsh"
        '';
      };
  };
}
