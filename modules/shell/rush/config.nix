{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) shell;
in {
  options.user.shell.rush = {
    enable = lib.mkEnableOption "rush shell configuration";
  };

  config = lib.mkIf shell.rush.enable {
    # rush is a POSIX shell with built-in autosuggestions, syntax
    # highlighting, Ctrl-R history search, and structured (JSON) completions
    # — so carapace, fzf key-bindings, zsh-autosuggestions and
    # zsh-syntax-highlighting all drop away. Only the shell itself plus `bat`
    # (cat replacement) ship here; lsd/tree/fzf/ripgrep come from
    # modules/core/user/packages.nix. The system-level wiring — /etc/shells,
    # login shell — lives in modules/finix/common.nix.
    environment.systemPackages = [
      pkgs.rush
      pkgs.bat
    ];

    manzil.users."${config.user.name}".files = {
      # rush reads profile.rush for login shells and config.rush for
      # interactive ones. Both are plain POSIX shell scripts (rush IS a POSIX
      # shell), so there is no `emulate sh` dance and no null_glob guard: a
      # glob with no matches stays literal, and `[ -f … ]` skips it.
      #
      # ~/Tokens/<NAME>.txt becomes $NAME. Login-only (not config.rush) so the
      # file reads happen once per session; children inherit through the
      # environment. Skips ANTHROPIC_API_KEY/OPENAI_API_KEY (agents must read
      # their own credential files) and anything holding a PEM block or
      # control chars.
      ".config/rush/profile.rush".text = ''
        . /etc/profile

        for file_path in "$HOME/Tokens"/*; do
          [ -f "$file_path" ] || continue
          var_name=$(basename "$file_path" .txt)
          [ -n "$var_name" ] || continue
          case $var_name in
            ANTHROPIC_API_KEY | OPENAI_API_KEY) continue ;;
            *[!a-zA-Z0-9_]*) continue ;;
            [0-9]*) continue ;;
          esac
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
      ".config/rush/config.rush".text = lib.mkMerge [
        (lib.mkBefore ''
          # rush only reads config.rush for interactive shells, so no
          # `[[ -o interactive ]]` guard is needed (unlike the bash/zsh
          # versions).

          # Prompt: bold green cwd, then a prompt char that is cyan on success,
          # red on failure. `prompt segment` + `prompt_pwd` are rush builtins;
          # `$?` is the previous command's status on entry to rush_prompt.
          rush_prompt() {
            rush_prompt_status=$?
            prompt segment --bold --fg green "$(prompt_pwd)"
            prompt async git-branch --ttl 5000 --prefix ' ' --fg bright-magenta -- git branch --show-current
            if test "$rush_prompt_status" = 0; then
              prompt segment --fg cyan '>'
            else
              prompt segment --fg red '>'
            fi
            prompt text ' '
          }

          rush_prompt_right() {
            if prompt async-pending; then
              case "$(( ''${rush_prompt_activity_frame:-0} % 4 ))" in
                0) prompt text '(^_^) ' ;;
                1) prompt text '(^o^) ' ;;
                2) prompt text '(^-^) ' ;;
                *) prompt text '(^_~) ' ;;
              esac
            elif test "''${rush_prompt_status:-0}" = 0; then
              prompt text '(^_^) '
            else
              prompt segment --fg red '(>_<) '
            fi
          }

          ${lib.concatStringsSep "\n" (lib.mapAttrsToList
            (k: v: "alias ${lib.escapeShellArg k}=${lib.escapeShellArg v}")
            shell.aliases)}
        '')
        shell.rcExtra
      ];
    };
  };
}
