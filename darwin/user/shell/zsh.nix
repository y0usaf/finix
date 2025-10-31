{config, ...}: {
  home-manager.users.y0usaf = {
    programs.zsh = {
      enable = true;

      shellAliases = {
        wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';

        lintcheck = "clear; statix check .; deadnix .";
        lintfix = "clear; statix fix .; deadnix .";
        claude = "bunx @anthropic-ai/claude-code";
        clauded = "bunx @anthropic-ai/claude-code --dangerously-skip-permissions";
        buildtime = "time (nix build .#darwinConfigurations.y0usaf-macbook.system --option eval-cache false)";

        "l." = "lsd -A | grep -E \"^\\\\.\"";
        la = "lsd -A --color=always --group-dirs=first --icon=always";
        ll = "lsd -l --color=always --group-dirs=first --icon=always";
        ls = "lsd -lA --color=always --group-dirs=first --icon=always";
        lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

        grep = "rg --color auto";
        dir = "dir --color=auto";
        egrep = "rg --color auto";
        fgrep = "rg -F --color auto";

        pkgs = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | uniq | rg -i";
        pkgcount = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | uniq | wc -l";

        svn = ''svn --config-dir "$XDG_CONFIG_HOME/subversion"'';
      };

      initContent = ''
        export_vars_from_files() {
            local dir_path=$1

            if [[ ! -d "$dir_path" ]]; then
                return 0
            fi

            local skip_for_opencode=("ANTHROPIC_API_KEY" "OPENAI_API_KEY")

            for file_path in "$dir_path"/*; do
                if [[ -f $file_path ]]; then
                    var_name=$(basename "$file_path" .txt)

                    if [[ ! $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                        continue
                    fi

                    if [[ " ''${skip_for_opencode[@]} " =~ " $var_name " ]]; then
                        continue
                    fi

                    local content=$(cat "$file_path" 2>/dev/null || echo "")
                    if [[ -z "$content" ]] || [[ $content =~ [[:cntrl:]] ]] || [[ $content == *"-----"* ]]; then
                        continue
                    fi

                    export $var_name="$content"
                fi
            done
        }
        export_vars_from_files "${config.user.homeDirectory}/Tokens"

        temppkg() {
          if [ -z "$1" ]; then
            echo "Usage: temppkg <package-name>"
            return 1
          fi
          nix shell nixpkgs#$1
        }

        temprun() {
          if [ -z "$1" ]; then
            echo "Usage: temprun <package-name> [args...]"
            return 1
          fi
          local pkg=$1
          shift
          nix run nixpkgs#$pkg -- "$@"
        }

        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=50000
        SAVEHIST=50000
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_SAVE_NO_DUPS
        setopt SHARE_HISTORY

        autoload -Uz compinit
        compinit

        PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
      '';
    };
  };
}
