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
    environment.variables.ZDOTDIR = "${config.user.homeDirectory}/.config/zsh";
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
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") (import ./aliases.nix {
                inherit config;
                flakeDirectory = config.user.paths.flake.path;
              })
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
            text = let
              settings = import ./settings.nix {inherit config;};
              libFunctions = import ../../../../lib/shell/zsh/functions.nix {};
              localFunctions = import ./functions.nix {inherit config;};
            in
              lib.concatStringsSep "\n" (
                [
                  "source \"$ZDOTDIR/aliases.zsh\""
                ]
                ++ lib.optional config.user.shell.zellij.enable "source \"$ZDOTDIR/zellij.zsh\""
                ++ [
                  (import ../../../../lib/shell/zsh/plugins.nix {inherit pkgs;})

                  settings.history

                  settings.completion

                  settings.prompt

                  libFunctions.temppkg
                  libFunctions.temprun
                  localFunctions.fanspeed
                ]
              );
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.enable {
          ".config/zsh/zellij.zsh" = {
            text =
              (import ../../../../lib/shell/zellij/config.nix {inherit lib;}).shellChecks
              + ''
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
        };
    };
  };
}
