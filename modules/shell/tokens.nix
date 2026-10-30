{
  config,
  ...
}: let
  loader = ''
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
in {
  manzil.users."${config.user.name}".files = {
    ".config/tokens.sh".text = loader;

    ".profile".text = ''
      [ -r "$HOME/.config/tokens.sh" ] && . "$HOME/.config/tokens.sh"
    '';
  };
}
