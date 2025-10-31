{pkgs, ...}: ''
  # Syntax highlighting - nushell default theme
  source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  ZSH_HIGHLIGHT_STYLES[default]='fg=10'
  ZSH_HIGHLIGHT_STYLES[command]='fg=6'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg=6,bold'
  ZSH_HIGHLIGHT_STYLES[string]='fg=2'
  ZSH_HIGHLIGHT_STYLES[error]='fg=1,bold'

  # Autosuggestions - dark gray (nushell hints)
  source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
''
