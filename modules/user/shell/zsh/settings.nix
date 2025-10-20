{config}: let
  inherit (config.user) homeDirectory;
in {
  history = ''
    HISTSIZE=10000
    SAVEHIST=10000
    HISTFILE="${homeDirectory}/.local/state/zsh/history"
    setopt HIST_IGNORE_DUPS
    setopt HIST_IGNORE_ALL_DUPS
    setopt HIST_IGNORE_SPACE
    setopt HIST_EXPIRE_DUPS_FIRST
    setopt SHARE_HISTORY
    setopt EXTENDED_HISTORY
  '';

  completion = ''
    zstyle ':completion:*' menu select
    zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|[._-]=* r:|=*' \
        'l:|=* r:|=*'
  '';

  prompt = ''
    PS1='%F{blue}%~%(?.%F{green}.%F{red})> %f'
  '';

  environment = ''
    export TERMINAL="${config.user.core.defaults.terminal}"
    export BROWSER="${config.user.core.defaults.browser}"
    export EDITOR="${config.user.core.defaults.editor}"
  '';
}
