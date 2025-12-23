{
  config,
  lib,
  ...
}: let
  shellIntegrationLib = import ../../../../lib/shell/zellij/config.nix {inherit lib;};
in {
  config = lib.mkIf config.user.shell.zellij.enable {
    home-manager.users.y0usaf = {
      programs.zellij = {
        enable = true;
        inherit (config.user.shell.zellij) package;
      };

      home.file = {
        ".config/zellij/config.kdl" = {
          text = ''
            hide_session_name false
            copy_on_select true
            show_startup_tips false
            on_force_close "quit"
            session_serialization false
            pane_frames true
            ${lib.optionalString config.user.shell.zellij.zjstatus.enable "default_layout \"zjstatus\""}
            ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} ${
                if lib.isString v
                then "\"${v}\""
                else builtins.toString v
              }")
              config.user.shell.zellij.settings)}
            ${lib.optionalString (config.user.shell.zellij.zjstatusHints.enable or false) ''
              plugins {
                zjstatus-hints location="https://raw.githubusercontent.com/y0usaf/zjstatus-hints/feat/custom-labels/zjstatus_hints.wasm" {
                  max_length ${toString config.user.shell.zellij.zjstatusHints.maxLength}
                  pipe_name "${config.user.shell.zellij.zjstatusHints.pipeName}"
                }
              }

              load_plugins {
                zjstatus-hints
              }
            ''}
            ${config.user.shell.zellij.themeConfig}
          '';
        };
        ".config/zsh/zellij.zsh" = lib.mkIf (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) {
          text = shellIntegrationLib.shellIntegration;
        };
        ".config/zellij/layouts/zjstatus.kdl" = lib.mkIf (config.user.shell.zellij.enable && config.user.shell.zellij.zjstatus.enable) {
          text = config.user.shell.zellij.zjstatus.layout;
        };
      };

      programs.zsh.initContent = lib.mkAfter (lib.optionalString (config.user.shell.zellij.autoStart && config.user.shell.zsh.enable) ''
        [[ -f "$HOME/.config/zsh/zellij.zsh" ]] && source "$HOME/.config/zsh/zellij.zsh"
      '');
    };
  };
}
