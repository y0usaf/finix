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
          tomoe_colour='\033[1;38;2;255;0;255m'
          moon_colour='\033[1;38;2;0;255;0m'
          ekko_colour='\033[1;38;2;0;255;255m'
          bozo_colour='\033[1;38;2;255;0;0m'
          reset='\033[0m'

          print_cats() {
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
