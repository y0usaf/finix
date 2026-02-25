{
  config,
  pkgs,
  ...
}: {
  home-manager.users.${config.user.name} = {
    programs.zsh = {
      enable = true;

      envExtra = ''
        export NH_DARWIN_FLAKE="${config.user.homeDirectory}/nixos"
      '';

      shellAliases =
        (import ../../../lib/shell/zsh/common-aliases.nix null)
        // (import ../../../lib/shell/zsh/darwin-aliases.nix null);

      initContent = ''
        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=50000
        SAVEHIST=50000
        setopt HIST_IGNORE_ALL_DUPS
        setopt HIST_SAVE_NO_DUPS
        setopt SHARE_HISTORY

        autoload -Uz compinit
        compinit

        PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '

        # nh configuration
        nhd() {
          clear
          local update=""
          local dry=""
          local OPTIND
          while getopts "du" opt; do
            case $opt in
              d) dry="--dry" ;;
              u) update="--update" ;;
              *) echo "Invalid option: -$OPTARG" >&2 ;;
            esac
          done
          shift $((OPTIND-1))
          nh darwin switch $update $dry "$@"
        }
      '';
    };

    home.packages = [
      pkgs.zsh-syntax-highlighting
      pkgs.zsh-autosuggestions
    ];
  };
}
