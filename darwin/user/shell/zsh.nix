{
  config,
  pkgs,
  ...
}: {
  home-manager.users.y0usaf = {
    programs.zsh = {
      enable = true;

      shellAliases = import ../../../lib/shell/zsh/common-aliases.nix {} // import ../../../lib/shell/zsh/darwin-aliases.nix {};

      initContent = ''
        ${import ../../../lib/shell/zsh/export-vars.nix {inherit config;}}

        ${(import ../../../lib/shell/zsh/functions.nix {}).temppkg}

        ${(import ../../../lib/shell/zsh/functions.nix {}).temprun}

        ${import ../../../lib/shell/zsh/plugins.nix {inherit pkgs;}}

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

    home.packages = [
      pkgs.zsh-syntax-highlighting
      pkgs.zsh-autosuggestions
    ];
  };
}
