{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  luinPin = inputPackages.luin.luin-pin;
  nh = inputPackages.nh.default.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./nh-iets.patch];
  });
  finix-switch = pkgs.writeShellApplication {
    name = "finix-switch";
    runtimeInputs = [pkgs.git pkgs.util-linux nh luinPin];
    text = ''
      dry=false
      if [ "''${1:-}" = --dry ]; then
        dry=true
        shift
      fi
      flake=''${NH_FLAKE:-$HOME/finix}
      host=$(cat /proc/sys/kernel/hostname)
      lock=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agent/finix-switch.lock
      mkdir -p "''${lock%/*}"
      if [ -n "$(git -C "$flake" status --porcelain --untracked-files=no)" ]; then
        echo "finix-switch: uncommitted changes in $flake are left out" >&2
      fi
      pinned=''${1:-}
      while :; do
        rev=$(git -C "$flake" rev-parse --verify "''${pinned:-HEAD}^{commit}")
        system=$(nix build --impure --no-link --print-out-paths --expr "(import (builtins.fetchGit { url = \"file://$flake\"; rev = \"$rev\"; allRefs = true; }) {}).nixosConfigurations.\"$host\".config.system.build.toplevel")
        exec 9>"$lock"
        if ! flock -n 9; then
          echo "finix-switch: waiting for another switch to finish ($lock)" >&2
          flock 9
        fi
        [ -z "$pinned" ] && [ "$(git -C "$flake" rev-parse HEAD)" != "$rev" ] || break
        echo "finix-switch: $flake moved past $rev during the build; building again" >&2
        exec 9>&-
      done
      from=$(readlink -f /run/current-system)
      if $dry; then
        printf '{"rev":"%s","from":"%s","to":"%s","switched":false,"dry":true}\n' "$rev" "$from" "$system"
        exit 0
      fi
      [ "$from" = "$system" ] || nh os switch "$system" >&2
      to=$(readlink -f /run/current-system)
      if [ "$to" != "$system" ]; then
        echo "finix-switch: /run/current-system is $to, not $system" >&2
        exit 1
      fi
      switched=false
      [ "$from" = "$to" ] || switched=true
      printf '{"rev":"%s","from":"%s","to":"%s","switched":%s}\n' "$rev" "$from" "$to" "$switched"
    '';
  };
in {
  environment = {
    systemPackages = [nh inputPackages.luin.default luinPin finix-switch];
    variables.NH_FLAKE = "${config.user.homeDirectory}/finix";
  };
}
