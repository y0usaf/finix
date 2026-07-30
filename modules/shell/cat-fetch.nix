{
  config,
  lib,
  ...
}: {
  options.user.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };
  config = lib.mkIf config.user.shell.cat-fetch.enable {
    user.shell.rcExtra = lib.mkAfter ''
      print_cats() {
        # Wallust rewrites shell-colors.sh on every theme change, so read it at
        # call time rather than baking colours into this file.
        if [ -f "$HOME/.cache/wallust/shell-colors.sh" ]; then
          . "$HOME/.cache/wallust/shell-colors.sh"
          local tomoe_colour="$WALLUST_COLOR13" # Magenta
          local moon_colour="$WALLUST_COLOR2"   # Green
          local ekko_colour="$WALLUST_COLOR12"  # Cyan
          local rudo_colour="$WALLUST_COLOR9"   # Bright red
        else
          local tomoe_colour='\033[38;5;13m'
          local moon_colour='\033[38;5;2m'
          local ekko_colour='\033[38;5;12m'
          local rudo_colour='\033[38;5;9m'
        fi
        local reset='\033[0m'
        echo -e "''${tomoe_colour} ⟋|､      ''${moon_colour}  ⟋|､      ''${ekko_colour}  ⟋|､      ''${rudo_colour}  ⟋|､
      ''${tomoe_colour}(°､ ｡ 7    ''${moon_colour}(°､ ｡ 7    ''${ekko_colour}(°､ ｡ 7    ''${rudo_colour}(°､ ｡ 7
      ''${tomoe_colour} |､  ~ヽ   ''${moon_colour} |､  ~ヽ   ''${ekko_colour} |､  ~ヽ   ''${rudo_colour} |､  ~ヽ
      ''${tomoe_colour} じしf_,)〳''${moon_colour} じしf_,)〳''${ekko_colour} じしf_,)〳''${rudo_colour} じしf_,)〳
      ''${rudo_colour}  [tomo]   ''${tomoe_colour}  [moon]   ''${moon_colour}  [ekko]   ''${ekko_colour}  [rudo]''${reset}"
      }

      print_cats
    '';
  };
}
