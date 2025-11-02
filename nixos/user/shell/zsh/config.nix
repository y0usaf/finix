{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell configuration";
  };
  config = lib.mkIf config.user.shell.zsh.enable {
    environment.variables.ZDOTDIR = "${config.user.configDirectory}/zsh";
    programs.zsh.enable = true;

    environment.systemPackages = [
      pkgs.zsh
      pkgs.bat
      pkgs.lsd
      pkgs.tree
      pkgs.zsh-syntax-highlighting
      pkgs.zsh-autosuggestions
    ];

    hjem.users.${config.user.name} = {
      files =
        {
          ".config/zsh/aliases.zsh" = {
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") (import ./aliases.nix {inherit config; nixosConfigDirectory = config.user.nixosConfigDirectory;})
            );
            clobber = true;
          };
          ".config/zsh/.zshenv" = {
            text =
              (import ../../../../lib/shell/zsh/export-vars.nix {inherit config;})
              + ''

                export TERMINAL="${config.user.defaults.terminal}"
                export BROWSER="${config.user.defaults.browser}"
                export EDITOR="${config.user.defaults.editor}"
              '';
            clobber = true;
          };
          ".config/zsh/.zshrc" = {
            text = lib.concatStringsSep "\n" (
              [
                "source \"$ZDOTDIR/aliases.zsh\""
              ]
              ++ lib.optional config.user.shell.zellij.enable "source \"$ZDOTDIR/zellij.zsh\""
              ++ [
                (import ./plugins.nix {inherit pkgs;})

                (import ./settings.nix {inherit config;}).history

                (import ./settings.nix {inherit config;}).completion

                (import ./settings.nix {inherit config;}).prompt

                (import ../../../../lib/shell/zsh/functions.nix {}).temppkg
                (import ../../../../lib/shell/zsh/functions.nix {}).temprun
                (import ./functions.nix {inherit config;}).fanspeed
              ]
            );
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.enable {
          ".config/zsh/zellij.zsh" = {
            text = ''
              # Skip if already in multiplexer or SSH session
              [[ -n "$ZELLIJ" || -n "$SSH_CONNECTION" || -n "$TMUX" ]] && return

              # Skip if in virtual console (TTY)
              # Fast path: TERM check (no subprocess)
              [[ "$TERM" == "linux" ]] && return

              # Robust fallback: device path check (minimal subprocess overhead)
              [[ $(readlink /proc/self/fd/0 2>/dev/null) =~ ^/dev/tty[0-9] ]] && return

              # Start Zellij
              if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
                zellij attach -c
              else
                zellij
              fi

              if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
                exit
              fi
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs (config.networking.hostName == "y0usaf-desktop") {
          ".config/zsh/.zprofile" = {
            text = ''
              if [[ $- == *i* ]]; then
                sudo nvidia-smi -pl 150
              fi
            '';
            clobber = true;
          };
        };
    };
  };
}
