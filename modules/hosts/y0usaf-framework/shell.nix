_: {
  # ~/.local/bin on PATH so `cu` (cu-workbench CLI) and other user-local
  # binaries are available in interactive shells.
  user.shell.rcExtra = ''
    case ":$PATH:" in
      *":$HOME/.local/bin:"*) ;;
      *) PATH="$HOME/.local/bin:$PATH" ;;
    esac
  '';
}
