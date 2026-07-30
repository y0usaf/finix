{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) shell;

  # Precomputed at build time, same reason as the bash module: `carapace
  # _carapace zsh` is a subprocess we would otherwise pay for on every shell
  # start. The sed drops the `export PATH=…/build/…/carapace/bin` line the
  # generator emits from the sandbox HOME.
  carapaceInit = pkgs.runCommand "carapace-init-zsh" {} ''
    export HOME=$(mktemp -d)
    ${pkgs.carapace}/bin/carapace _carapace zsh \
      | ${pkgs.gnused}/bin/sed '/\/build\/.*carapace\/bin/d' > $out
  '';

  autosuggestions = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
  syntaxHighlighting = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
in {
  options.user.shell.zsh = {
    enable = lib.mkEnableOption "zsh shell configuration";
  };

  config = lib.mkIf shell.zsh.enable {
    # NOTE: finix has no programs.zsh module (only bash and fish), and
    # compat-import drops `programs.*` anyway. The system-level wiring —
    # /etc/zshenv, environment.shells, login shell — lives in finix/common.nix.
    environment.systemPackages = [
      pkgs.zsh
      pkgs.carapace
      pkgs.fzf
      pkgs.bat
      pkgs.lsd
      pkgs.tree
    ];

    manzil.users."${config.user.name}".files = {
      # zsh reads .zprofile for login shells and .zshrc for interactive ones on
      # its own — unlike bash, there is no manual `. ~/.zshrc` chaining here.
      #
      # `emulate sh -c` is required: /etc/profile and its profile.d drop-ins are
      # POSIX sh, and zsh's default word splitting would mangle them.
      #
      # ~/Tokens/<NAME>.txt becomes $NAME. Login-only (not .zshrc) so the file
      # reads happen once per session; children inherit through the environment.
      # Skips ANTHROPIC_API_KEY/OPENAI_API_KEY (agents must read their own
      # credential files) and anything holding a PEM block or control chars.
      ".zprofile".text = ''
        emulate sh -c '. /etc/profile'

        # (N) = null_glob for this pattern only. Without it zsh treats an empty
        # ~/Tokens as a fatal "no matches found" and aborts the login shell;
        # bash silently passed the literal pattern to the -f test instead.
        for file_path in "$HOME/Tokens"/*(N); do
          [ -f "$file_path" ] || continue
          var_name=$(basename "$file_path" .txt)
          case $var_name in
            ANTHROPIC_API_KEY | OPENAI_API_KEY) continue ;;
          esac
          [[ $var_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || continue
          content=$(cat "$file_path" 2>/dev/null) || continue
          [ -n "$content" ] || continue
          case $content in
            *-----* | *[[:cntrl:]]*) continue ;;
          esac
          export "$var_name=$content"
        done
        unset file_path var_name content
      '';

      # mkBefore pins this base block ahead of user.shell.rcExtra, which carries
      # the feature modules' fragments at default (1000) priority.
      ".zshrc".text = lib.mkMerge [
        (lib.mkBefore ''
          # Interactive only — scp/rsync break if a non-interactive shell prints.
          [[ -o interactive ]] || return

          # HISTFILE comes from environment.sessionVariables
          # (modules/core/user/session/xdg.nix); only behaviour is set here.
          HISTSIZE=10000
          SAVEHIST=10000
          # bash equivalent was HISTCONTROL=ignoreboth:erasedups + shopt histappend.
          setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY
          setopt HIST_IGNORE_SPACE HIST_IGNORE_ALL_DUPS HIST_SAVE_NO_DUPS
          setopt HIST_REDUCE_BLANKS

          # Bold green cwd, then a prompt char that is cyan on success, red on
          # failure. `%(?.A.B)` is native prompt expansion on $? — no
          # PROMPT_COMMAND hook needed, which is why this is one line and the
          # bash version was a function.
          PROMPT='%B%F{green}%~%f%b%(?.%F{cyan}.%F{red})>%f '

          # compinit must run before carapace's `compdef` calls.
          # -C skips the fpath ownership audit: every completion dir here is an
          # immutable root-owned /nix/store path, and the audit is most of
          # compinit's cost (~150-400ms cold, ~0.4ms warm).
          autoload -Uz compinit
          compinit -C -d "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

          . ${carapaceInit}

          # Ctrl-R history search, Ctrl-T file search, Alt-C cd.
          . ${pkgs.fzf}/share/fzf/key-bindings.zsh

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList
            (k: v: "alias ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
            shell.aliases)}

          # Ghost-text completion from history. Loads after the widgets above so
          # it can wrap them.
          . ${autosuggestions}
          ZSH_AUTOSUGGEST_STRATEGY=(history completion)

          # MUST BE LAST of the base block. Upstream README §"Why must
          # zsh-syntax-highlighting.zsh be sourced at the end": it registers a
          # zle-line-pre-redraw hook and only highlights widgets that already
          # exist when it loads.
          . ${syntaxHighlighting}
        '')
        shell.rcExtra
      ];
    };
  };
}
