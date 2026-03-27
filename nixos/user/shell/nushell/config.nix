{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.shell.nushell = {
    enable = lib.mkEnableOption "nushell shell configuration";
  };
  config = lib.mkIf config.user.shell.nushell.enable {
    environment.systemPackages = [
      pkgs.nushell
      pkgs.carapace
      pkgs.bat
      pkgs.lsd
      pkgs.tree
    ];

    bayt.users."${config.user.name}" = {
      files =
        {
          ".config/nushell/config.nu" = {
            text = let
              settings = import ./settings.nix {inherit config;};
              libFunctions = import ../../../../lib/shell/nushell/functions.nix {};
              aliases = import ./aliases.nix {
                inherit lib config;
                flakeDirectory = config.user.paths.flake.path;
              };
              localFunctions = import ./functions.nix {inherit config;};
            in
              lib.concatStringsSep "\n" (
                [
                  settings.banner
                  settings.history
                  settings.completion
                  settings.keybindings
                  settings.carapace
                  aliases
                  libFunctions.temppkg
                  libFunctions.temprun
                  localFunctions
                ]
                ++ lib.optional config.user.shell.zellij.enable "source ~/.config/nushell/zellij.nu"
              );
            clobber = true;
          };
          ".config/nushell/env.nu" = {
            text =
              (import ../../../../lib/shell/nushell/export-vars.nix {inherit config;})
              + ''

                $env.TERMINAL = "${config.user.defaults.terminal}"
                $env.BROWSER = "${config.user.defaults.browser}"
                $env.EDITOR = "${config.user.defaults.editor}"
              '';
            clobber = true;
          };
          ".config/nushell/login.nu" = {
            text = "";
            clobber = true;
          };
          ".config/nushell/carapace.nu" = {
            source = pkgs.runCommand "carapace-init-nu" {} ''
              export HOME=$(mktemp -d)
              ${pkgs.carapace}/bin/carapace _carapace nushell | ${pkgs.gnused}/bin/sed '/\/build\/.*carapace\/bin/d' > $out
            '';
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.enable {
          ".config/nushell/zellij.nu" = {
            text = ''
              # Skip if already in a multiplexer or SSH session
              if ("ZELLIJ" in $env) or ("SSH_CONNECTION" in $env) or ("TMUX" in $env) { return }

              # Skip if in virtual console
              if ($env.TERM? | default "" ) == "linux" { return }

              # Start Zellij
              if ($env.ZELLIJ_AUTO_ATTACH? | default "false") == "true" {
                exec zellij attach -c
              } else {
                exec zellij
              }
            '';
            clobber = true;
          };
        };
    };

    # Set prompt in env.nu so it's available early
    usr.files.".config/nushell/env.nu" = {
      text = lib.mkAfter (import ./settings.nix {inherit config;}).prompt;
      clobber = true;
    };
  };
}
