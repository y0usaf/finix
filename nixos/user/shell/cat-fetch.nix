{
  config,
  lib,
  ...
}: {
  options.user.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };
  config = lib.mkIf config.user.shell.cat-fetch.enable {
    usr.files = lib.optionalAttrs config.user.shell.zsh.enable {
      ".config/zsh/.zshrc" = {
        text = lib.mkAfter ''
          source "$ZDOTDIR/cat-fetch.zsh"
        '';
        clobber = true;
      };
      ".config/zsh/cat-fetch.zsh" = {
        text = ''
          print_cats() {
            # Source Wallust terminal colors (palette references that update dynamically)
            if [ -f "$HOME/.cache/wallust/shell-colors.sh" ]; then
              source "$HOME/.cache/wallust/shell-colors.sh"
              local tomoe_colour="$WALLUST_COLOR13"  # Magenta
              local moon_colour="$WALLUST_COLOR2"   # Green
              local ekko_colour="$WALLUST_COLOR12"  # Cyan
              local bozo_colour="$WALLUST_COLOR9"   # Bright red
            else
              # Fallback: use basic ANSI colors if Wallust not initialized
              local tomoe_colour='\033[38;5;13m'    # Bright magenta
              local moon_colour='\033[38;5;2m'     # Green
              local ekko_colour='\033[38;5;12m'    # Bright cyan
              local bozo_colour='\033[38;5;9m'     # Bright red
            fi

            local reset='\033[0m'

            echo -e "''${tomoe_colour} ⟋|､      ''${moon_colour}  ⟋|､      ''${ekko_colour}  ⟋|､      ''${bozo_colour}  ⟋|､
          ''${tomoe_colour}(°､ ｡ 7    ''${moon_colour}(°､ ｡ 7    ''${ekko_colour}(°､ ｡ 7    ''${bozo_colour}(°､ ｡ 7
          ''${tomoe_colour} |､  ~ヽ   ''${moon_colour} |､  ~ヽ   ''${ekko_colour} |､  ~ヽ   ''${bozo_colour} |､  ~ヽ
          ''${tomoe_colour} じしf_,)〳''${moon_colour} じしf_,)〳''${ekko_colour} じしf_,)〳''${bozo_colour} じしf_,)〳
          ''${bozo_colour}  [tomo]   ''${tomoe_colour}  [moon]   ''${moon_colour}  [ekko]   ''${ekko_colour}  [bozo]''${reset}"
          }

          print_cats
        '';
        clobber = true;
      };
    };
  };
}
