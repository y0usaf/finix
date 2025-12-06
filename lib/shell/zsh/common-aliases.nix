# Aliases that work on both NixOS and Darwin
_: {
  # XDG compliance
  wget = ''wget --hsts-file="$XDG_DATA_HOME/wget-hsts"'';

  # Development tools
  lintcheck = "clear; statix check .; deadnix .";
  lintfix = "clear; statix fix .; deadnix .";

  # Wallust wrapper (auto-updates pywalfox)
  wallust = "wt";
  claude = "bunx --bun @anthropic-ai/claude-code";
  clauded = "bunx --bun @anthropic-ai/claude-code --dangerously-skip-permissions";
  code = "bunx -bun @just-every/code";
  codex = "bunx --bun @openai/codex";
  gemini = "bunx --bun @google/gemini-cli@preview";

  # File listing with lsd
  "l." = "lsd -A | grep -E \"^\\\\.\"";
  la = "lsd -A --color=always --group-dirs=first --icon=always";
  ll = "lsd -l --color=always --group-dirs=first --icon=always";
  ls = "lsd -lA --color=always --group-dirs=first --icon=always";
  lt = "lsd -A --tree --color=always --group-dirs=first --icon=always";

  # Grep replacements with ripgrep
  grep = "rg --color auto";
  dir = "dir --color=auto";
  egrep = "rg --color auto";
  fgrep = "rg -F --color auto";

  # Subversion XDG compliance
  svn = ''svn --config-dir "$XDG_CONFIG_HOME/subversion"'';
}
