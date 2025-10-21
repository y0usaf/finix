{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.user) name tokensDirectory nixosConfigDirectory;
  functionsData = import ./functions.nix {inherit config;};
  settingsData = import ./settings.nix {inherit config;};
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
    ];

    hjem.users.${name} = {
      files =
        {
          ".config/zsh/aliases.zsh" = {
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (k: v: "alias -- ${lib.escapeShellArg k}=${lib.escapeShellArg v}") (import ./aliases.nix {inherit nixosConfigDirectory;})
            );
            clobber = true;
          };
          ".config/zsh/.zshenv" = {
            text = let
              tokenFunctionScript = ''
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


                export TERMINAL="${config.user.core.defaults.terminal}"
                export BROWSER="${config.user.core.defaults.browser}"
                export EDITOR="${config.user.core.defaults.editor}"
              '';
            in
              tokenFunctionScript;
            clobber = true;
          };
          ".config/zsh/.zshrc" = {
            text = lib.concatStringsSep "\n" [
              # Environment variables
              settingsData.environment

              # Load aliases
              "source \"$ZDOTDIR/aliases.zsh\""

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
            ];
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
