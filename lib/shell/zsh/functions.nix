{}: {
  # Temporary package shell
  temppkg = ''
    temppkg() {
      if [ -z "$1" ]; then
        echo "Usage: temppkg package_name"
        return 1
      fi
      nix-shell -p "$1" --run "exec $SHELL"
    }
  '';

  # Temporary run
  temprun = ''
    temprun() {
      if [ -z "$1" ]; then
        echo "Usage: temprun <package-name> [args...]"
        return 1
      fi
      local pkg=$1
      shift
      nix run nixpkgs#$pkg -- "$@"
    }
  '';
}
