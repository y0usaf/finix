{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) shell;

  wallustCfg = config.user.appearance.wallust;
  wallustBin = "${pkgs.wallust}/bin/wallust";
in {
  options.user.shell.rush = {
    enable = lib.mkEnableOption "rush shell configuration";
  };

  config = lib.mkIf shell.rush.enable {
    environment.systemPackages = [
      pkgs.rush
      pkgs.bat
    ];

    manzil.users."${config.user.name}".files = {
      ".config/rush/profile.rush".text = ''
        . /etc/profile

        if command -v wallust >/dev/null 2>&1; then
          ${lib.concatMapStringsSep "\n" (dir: "mkdir -p \"$HOME${lib.removePrefix "~" dir}\"") wallustCfg.startupDirs}
          ${wallustBin} cs "$HOME/.config/wallust/colorschemes/${wallustCfg.defaultTheme}.json"
        fi

        for file_path in "$HOME/Tokens"/*; do
          [ -f "$file_path" ] || continue
          var_name=$(basename "$file_path" .txt)
          [ -n "$var_name" ] || continue
          case $var_name in
            ANTHROPIC_API_KEY | OPENAI_API_KEY) continue ;;
            *[!a-zA-Z0-9_]*) continue ;;
            [0-9]*) continue ;;
          esac
          content=$(cat "$file_path" 2>/dev/null) || continue
          [ -n "$content" ] || continue
          case $content in
            *-----* | *[[:cntrl:]]*) continue ;;
          esac
          export "$var_name=$content"
        done
        unset file_path var_name content
      '';

      ".config/rush/config.rush".text = lib.mkMerge [
        (lib.mkBefore ''

          rush_prompt() {
            rush_prompt_status=$?
            prompt segment --bold --fg green "$(prompt_pwd)"
            if test "$rush_prompt_status" = 0; then
              prompt segment --fg cyan '>'
            else
              prompt segment --fg red '>'
            fi
            prompt text ' '
          }

          rush_prompt_right() {
            prompt segment --fg bright-blue "$(date +'%Y-%m-%d %H:%M')"
          }

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList
            (k: v: "alias ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
            shell.aliases)}
        '')
        shell.rcExtra
      ];
    };
  };
}
