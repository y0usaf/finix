{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.user) name tokensDirectory nixosConfigDirectory;
  functionsData = import ./functions.nix {inherit config;};
  settingsData = import ./settings.nix {inherit config;};
  pluginsData = import ./plugins.nix {inherit pkgs;};
in {
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

    hjem.users.${name} = {
      files =
        {
          ".config/zsh/aliases.zsh" = {
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") (import ./aliases.nix {inherit config nixosConfigDirectory;})
            );
            clobber = true;
          };
          ".config/zsh/.zshenv" = {
            text = ''
              export_vars_from_files() {
                  local dir_path=$1

                  # Check if directory exists
                  if [[ ! -d "$dir_path" ]]; then
                      return 0
                  fi

                  local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

                  for file_path in "$dir_path"/*; do
                      if [[ -f $file_path ]]; then
                          var_name=$(basename "$file_path" .txt)

                          # Skip if variable name is invalid
                          if [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                              continue
                          fi

                          if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                              continue
                          fi

                          # Read file content and skip if it contains problematic characters
                          local content=$(cat "$file_path" 2>/dev/null || echo "")
                          if [[ -z "$content" ]] || [[ $content =~ [[:cntrl:]] ]] || [[ $content == *"-----"* ]]; then
                              continue
                          fi

                          export $var_name="$content"
                      fi
                  done
              }
              export_vars_from_files "${tokensDirectory}"


              export TERMINAL="${config.user.defaults.terminal}"
              export BROWSER="${config.user.defaults.browser}"
              export EDITOR="${config.user.defaults.editor}"
            '';
            clobber = true;
          };
          ".config/zsh/.zshrc" = {
            text = lib.concatStringsSep "\n" (
              [
                # Load aliases
                "source \"$ZDOTDIR/aliases.zsh\""
              ]
              ++ lib.optional config.user.shell.zellij.enable "source \"$ZDOTDIR/zellij.zsh\""
              ++ [
                # Plugins
                pluginsData

                # History settings
                settingsData.history

                # Completion settings
                settingsData.completion

                # Prompt
                settingsData.prompt

                # Functions
                functionsData.temppkg
                functionsData.temprun
                functionsData.fanspeed
              ]
            );
            clobber = true;
          };
        }
        // lib.optionalAttrs config.user.shell.zellij.enable {
          ".config/zsh/zellij.zsh" = {
            text = ''
              if [[ -z "$ZELLIJ" ]] && [[ -t 0 ]]; then
                if [[ "$ZELLIJ_AUTO_ATTACH" == "true" ]]; then
                  zellij attach -c
                else
                  zellij
                fi

                if [[ "$ZELLIJ_AUTO_EXIT" == "true" ]]; then
                  exit
                fi
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
