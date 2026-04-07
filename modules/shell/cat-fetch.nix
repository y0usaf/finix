{
  config,
  lib,
  ...
}: {
  options.user.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };
  config = lib.mkIf config.user.shell.cat-fetch.enable {
    bayt.users."${config.user.name}".files =
      lib.optionalAttrs config.user.shell.zsh.enable {
        ".config/zsh/.zshrc" = {
          text = lib.mkAfter ''
            source "$ZDOTDIR/cat-fetch.zsh"
          '';
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
        };
      }
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            source ~/.config/nushell/cat-fetch.nu
          '';
        };
        ".config/nushell/cat-fetch.nu" = {
          text = ''
            def print_cats [] {
              # Use terminal palette colors (indices 0-15 controlled by Wallust)
              let e = $"\u{1b}"
              let tomoe = $"($e)[38;5;13m"  # Magenta
              let moon = $"($e)[38;5;2m"    # Green
              let ekko = $"($e)[38;5;12m"   # Cyan
              let bozo = $"($e)[38;5;9m"    # Bright red
              let r = (ansi reset)

              let line1 = $"($tomoe) ⟋|､      ($moon)  ⟋|､      ($ekko)  ⟋|､      ($bozo)  ⟋|､"
              let line2 = [$tomoe "(°､ ｡ 7    " $moon "(°､ ｡ 7    " $ekko "(°､ ｡ 7    " $bozo "(°､ ｡ 7"] | str join
              let line3 = $"($tomoe) |､  ~ヽ   ($moon) |､  ~ヽ   ($ekko) |､  ~ヽ   ($bozo) |､  ~ヽ"
              let line4 = [$tomoe " じしf_,)〳" $moon " じしf_,)〳" $ekko " じしf_,)〳" $bozo " じしf_,)〳"] | str join
              let line5 = $"($bozo)  [tomo]   ($tomoe)  [moon]   ($moon)  [ekko]   ($ekko)  [bozo]($r)"

              print ([$line1 $line2 $line3 $line4 $line5] | str join "\n")
            }

            print_cats
          '';
        };
      };
  };
}
