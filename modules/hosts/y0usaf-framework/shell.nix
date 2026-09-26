_: {
  user.shell.rcExtra = ''
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
  '';
}
