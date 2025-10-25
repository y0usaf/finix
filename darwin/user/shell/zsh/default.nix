{pkgs, ...}: {
  home-manager.users.y0usaf = {
    programs.zsh = {
      enable = true;

      shellAliases = {
        # XDG compliance
        wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';

        # Development
        lintcheck = "clear; statix check .; deadnix .";
        lintfix = "clear; statix fix .; deadnix .";
        clauded = "claude --dangerously-skip-permissions";
        buildtime = "time (nix build .#darwinConfigurations.y0usaf-macbook.system --option eval-cache false)";

        # Navigation
        "l." = "lsd -A | grep -E \"^\\\\.\"";
        la = "lsd -A --color=always --group-dirs=first --icon=always";
        ll = "lsd -l --color=always --group-dirs=first --icon=always";
        ls = "lsd -lA --color=always --group-dirs=first --icon=always";
        lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

        # Search
        grep = "rg --color auto";
        dir = "dir --color=auto";
        egrep = "rg --color auto";
        fgrep = "rg -F --color auto";

        # System (Darwin-specific)
        pkgs = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | uniq | rg -i";
        pkgcount = "nix-store --query --requisites /run/current-system/sw | cut -d- -f2- | sort | uniq | wc -l";

        # Version control
        svn = ''svn --config-dir "$XDG_CONFIG_HOME/subversion"'';
        hmpush = "git -C /Users/y0usaf/nixos-clean push origin main";
        hmpull = "git -C /Users/y0usaf/nixos-clean fetch origin && git -C /Users/y0usaf/nixos-clean reset --hard origin/main";
      };

      initExtra = ''
        # Token export function
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
        export_vars_from_files "/Users/y0usaf/Tokens"

        # Temporary package functions
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

        # History settings
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=50000
        SAVEHIST=50000
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_SAVE_NO_DUPS
        setopt SHARE_HISTORY

        # Completion
        autoload -Uz compinit
        compinit

        # Simple prompt
        PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '
      '';
    };

    home.packages = with pkgs; [
      bat
      lsd
      tree
      ripgrep
      statix
      deadnix
    ];
  };
}
