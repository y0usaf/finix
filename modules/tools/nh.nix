{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  finix-switch = pkgs.writeShellApplication {
    name = "finix-switch";
    runtimeInputs = [pkgs.git pkgs.util-linux inputPackages.nh.default];
    text = ''
      flake=''${NH_FLAKE:-$HOME/finix}
      host=$(cat /proc/sys/kernel/hostname)
      lock=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agent/finix-switch.lock
      mkdir -p "''${lock%/*}"
      if [ -n "$(git -C "$flake" status --porcelain --untracked-files=no)" ]; then
        echo "finix-switch: uncommitted changes in $flake are left out" >&2
      fi
      while :; do
        rev=$(git -C "$flake" rev-parse HEAD)
        system=$(nix build --no-link --print-out-paths "git+file://$flake?rev=$rev#nixosConfigurations.$host.config.system.build.toplevel")
        exec 9>"$lock"
        if ! flock -n 9; then
          echo "finix-switch: waiting for another switch to finish ($lock)" >&2
          flock 9
        fi
        [ "$(git -C "$flake" rev-parse HEAD)" != "$rev" ] || break
        echo "finix-switch: $flake moved past $rev during the build; building again" >&2
        exec 9>&-
      done
      from=$(readlink -f /run/current-system)
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
    systemPackages = [inputPackages.nh.default finix-switch];
    variables.NH_FLAKE = "${config.user.homeDirectory}/finix";
  };
  user.shell.rcExtra = lib.mkAfter ''
    nhs() {
      clear
      local update=""
      local dry=""
      local nix=""
      while [ $# -gt 0 ]; do
        case $1 in
          -d|--dry) dry="--dry" ;;
          -u|--update) update="--update" ;;
          -du|-ud) dry="--dry"; update="--update" ;;
          --nix) nix=1 ;;
          *) break ;;
        esac
        shift
      done
      if [ -n "$nix" ]; then
        GC_DONT_GC=1 nh os switch $update $dry "$@"
        return
      fi
      if [ -n "$update" ]; then
        nix flake update --flake "$NH_FLAKE" || return
      fi
      local out="$XDG_RUNTIME_DIR/nhs-system"
      rm -f "$out"
      if ! iets build --impure -o "$out" "$NH_FLAKE#nixosConfigurations.$(hostname).config.system.build.toplevel"; then
        echo "nhs: iets failed; 'nhs --nix' evaluates with nix instead" >&2
        return 1
      fi
      nh os switch $dry "$@" "$out"
      local rc=$?
      rm -f "$out"
      return $rc
    }
    alias nhd="nhs -d"
    alias nhu="nhs -u"
    alias nhud="nhs -ud"
    alias nhc="nh clean all"
  '';
}
