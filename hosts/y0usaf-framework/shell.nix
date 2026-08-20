_: {
  user.shell = {
    rush.enable = true;
    cat-fetch.enable = true;
    ekko = {
      enable = true;
      autoStart = true;
      open = true;
    };
    # ~/.local/bin on PATH so `cu` (cu-workbench CLI) and other user-local
    # binaries are available in interactive shells. Same pattern as
    # modules/dev/python.nix (rcExtra PATH prepend).
    rcExtra = ''
      case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) PATH="$HOME/.local/bin:$PATH" ;;
      esac
    '';
  };
}
