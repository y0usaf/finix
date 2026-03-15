{
  config,
  lib,
  ...
}: {
  options.user.shell.cat-fetch = {
    enable = lib.mkEnableOption "cat fetch display on shell startup";
  };
  config = lib.mkIf config.user.shell.cat-fetch.enable {
    usr.files =
      lib.optionalAttrs config.user.shell.zsh.enable {
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
      }
      // lib.optionalAttrs config.user.shell.nushell.enable {
        ".config/nushell/config.nu" = {
          text = lib.mkAfter ''
            source ~/.config/nushell/cat-fetch.nu
          '';
          clobber = true;
        };
        ".config/nushell/cat-fetch.nu" = {
          text = ''
            def print_cats [] {
              let colors_file = $"($env.HOME)/.cache/wallust/shell-colors.sh"
              mut tomoe = (ansi magenta)
              mut moon = (ansi green)
              mut ekko = (ansi cyan)
              mut bozo = (ansi red)

              if ($colors_file | path exists) {
                # Parse wallust shell colors
                let colors = (open $colors_file | lines | where $it =~ '=' | each { |line|
                  let parts = ($line | str replace "export " "" | split column "=" name value)
                  {name: ($parts | get name.0), value: ($parts | get value.0 | str replace -a "'" "" | str replace -a '"' '''')}
                } | reduce -f {} { |it, acc| $acc | merge {($it.name): $it.value} })
                $tomoe = ($colors | get -i WALLUST_COLOR13 | default (ansi magenta))
                $moon = ($colors | get -i WALLUST_COLOR2 | default (ansi green))
                $ekko = ($colors | get -i WALLUST_COLOR12 | default (ansi cyan))
                $bozo = ($colors | get -i WALLUST_COLOR9 | default (ansi red))
              }

              let reset = (ansi reset)
              print $"($tomoe) ⟋|､      ($moon)  ⟋|､      ($ekko)  ⟋|､      ($bozo)  ⟋|､
            ($tomoe)\(°､ ｡ 7    ($moon)\(°､ ｡ 7    ($ekko)\(°､ ｡ 7    ($bozo)\(°､ ｡ 7
            ($tomoe) |､  ~ヽ   ($moon) |､  ~ヽ   ($ekko) |､  ~ヽ   ($bozo) |､  ~ヽ
            ($tomoe) じしf_,)〳($moon) じしf_,)〳($ekko) じしf_,)〳($bozo) じしf_,)〳
            ($bozo)  [tomo]   ($tomoe)  [moon]   ($moon)  [ekko]   ($ekko)  [bozo]($reset)"
            }

            print_cats
          '';
          clobber = true;
        };
      };
  };
}
