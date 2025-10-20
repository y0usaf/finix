{config}: {
  fanspeed =
    if config.networking.hostName == "y0usaf-laptop"
    then ''
      fanspeed() {
          if [ -z "$1" ]; then
              echo "Usage: fanspeed <percentage>"
              return 1
          fi
          local speed="$1"
          asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f gpu
          asusctl fan-curve -m quiet -D "30c:$speed,40c:$speed,50c:$speed,60c:$speed,70c:$speed,80c:$speed,90c:$speed,100c:$speed" -e true -f cpu
      }
    ''
    else "";

  temppkg = ''
    temppkg() {
        if [ -z "$1" ]; then
            echo "Usage: temppkg package_name"
            return 1
        fi
        nix-shell -p "$1" --run "exec $SHELL"
    }
  '';

  temprun = ''
    temprun() {
        if [ -z "$1" ]; then
            echo "Usage: temprun package_name [args...]"
            return 1
        fi
        local pkg="$1"
        shift
        nix run "nixpkgs#$pkg" -- "$@"
    }
  '';
}
