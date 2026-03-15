# Cross-platform aliases for Nushell
# Nushell aliases cannot contain pipes or env var expansion at call time.
# Complex aliases that need those features use `def` commands instead.
_: ''
  # Development tools (must be def - semicolons in aliases execute immediately)
  def lintcheck [] { clear; ^statix check .; ^deadnix . }
  def lintfix [] { clear; ^statix fix .; ^deadnix . }

  # Wallust wrapper
  alias wt = wallust

  # Claude Code
  alias claude = claude --allow-dangerously-skip-permissions

  # AI CLI tools via bunx
  alias buncodex = bunx --bun @openai/codex
  alias gemini = bunx --bun @google/gemini-cli@preview

  # File listing with lsd
  alias la = lsd -A --color=always --group-dirs=first --icon=always
  alias ll = lsd -l --color=always --group-dirs=first --icon=always
  alias ls = lsd -lA --color=always --group-dirs=first --icon=always
  alias lt = lsd -A --tree --color=always --group-dirs=first --icon=always

  # Grep replacements with ripgrep
  def grep [...args: string] { ^rg --color auto ...$args }
  def egrep [...args: string] { ^rg --color auto ...$args }
  def fgrep [...args: string] { ^rg -F --color auto ...$args }

  # Hidden files listing (uses pipe - must be def)
  def "l." [] { ^lsd -A | lines | where $it =~ '^\.' }

  # XDG compliance (uses env var expansion - must be def)
  def wget [...args: string] { ^wget $"--hsts-file=($env.XDG_DATA_HOME)/wget-hsts" ...$args }
  def svn [...args: string] { ^svn --config-dir $"($env.XDG_CONFIG_HOME)/subversion" ...$args }
''
