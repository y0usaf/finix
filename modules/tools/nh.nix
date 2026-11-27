{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  luinPin = inputPackages.luin.luin-pin;
  nhPatched = inputPackages.nh.default.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./nh-iets.patch];
  });
  nh = pkgs.symlinkJoin {
    name = "nh-wrapped";
    paths = [nhPatched];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/nh \
        --set-default NH_FILE ${lib.escapeShellArg "${config.user.homeDirectory}/finix/default.nix"} \
        --set-default NH_ATTRP ${lib.escapeShellArg "nixosConfigurations.${config.networking.hostName}"}
    '';
  };
  ship = pkgs.writeShellApplication {
    name = "ship";
    runtimeInputs = [pkgs.coreutils pkgs.git pkgs.gnugrep pkgs.nix pkgs.util-linux inputPackages.iets.default nh luinPin];
    text = ''
            die() { echo "ship: $*" >&2; exit 1; }

            repo=""
            input=""
            while [ "$#" -gt 0 ]; do
              case "$1" in
                -h | --help)
                  echo "usage: ship [REPO] [--input NAME]"
                  exit 0
                  ;;
                --input)
                  [ "$#" -ge 2 ] || die "--input wants an input name"
                  input=$2
                  shift 2
                  ;;
                -*)
                  die "unknown option: $1"
                  ;;
                *)
                  [ -z "$repo" ] || die "unexpected argument: $1"
                  repo=$1
                  shift
                  ;;
              esac
            done

            finix=$(realpath -m "''${FINIX_DIR:-$HOME/finix}")
            remotes=''${SHIP_FINIX_REMOTES:-github forgejo}
            lock=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/agent/finix-switch.lock
            repo=$(realpath "''${repo:-$PWD}")

            git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "$repo is not a git repository"
            dirty=$(git -C "$repo" status --porcelain --untracked-files=no)
            [ -z "$dirty" ] || { printf 'ship: %s has uncommitted changes:\n%s\n' "$repo" "$dirty" >&2; exit 1; }
            branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || die "$repo has a detached HEAD"
            rev=$(git -C "$repo" rev-parse HEAD)
            subject=$(git -C "$repo" log -1 --format=%s)

            switch_and_push_finix() {
              local finix_rev
              finix_rev=$(git -C "$finix" rev-parse HEAD)
              nh os switch --impure "git+file://$finix?rev=$finix_rev" 9>&-
              for remote in $remotes; do
                git -C "$finix" push "$remote" HEAD 9>&- || die "cannot push $finix to $remote"
              done
            }

            lock_finix() {
              mkdir -p "''${lock%/*}"
              exec 9>"$lock"
              if ! flock -n 9; then
                echo "ship: waiting for another switch ($lock)" >&2
                flock 9
              fi
              git -C "$finix" symbolic-ref --quiet HEAD >/dev/null || die "$finix has a detached HEAD"
              [ -z "$(git -C "$finix" status --porcelain --untracked-files=no)" ] || die "$finix has uncommitted changes"
            }

            if [ "$repo" = "$finix" ]; then
              [ -z "$input" ] || die "--input is not valid when shipping $finix directly"
              lock_finix
              switch_and_push_finix
              echo "ship: finix $rev"
              exit 0
            fi

            if git -C "$finix" rev-parse --git-dir >/dev/null 2>&1; then
              [ -z "$(git -C "$finix" status --porcelain --untracked-files=no)" ] || die "$finix has uncommitted changes"
            fi

            if [ -f "$repo/.luin/pins.lock.json" ] && [ -f "$repo/default.nix" ]; then
              sys=$(nix eval --raw --impure --expr builtins.currentSystem)
              if nix eval --impure -f "$repo" --apply "x: x ? checks && x.checks ? $sys" 2>/dev/null | grep -qx true; then
                echo "ship: nix build checks $repo" >&2
                nix build --impure --no-link -f "$repo" "checks.$sys"
              fi
            elif [ -f "$repo/flake.nix" ]; then
              echo "ship: nix flake check $repo" >&2
              nix flake check --no-write-lock-file "$repo"
            fi

            echo "ship: push $branch $rev" >&2
            git -C "$repo" push origin "HEAD:$branch"

            if [ -z "$input" ]; then
              origin=$(git -C "$repo" remote get-url origin)
              matches=$(luin-pin -C "$finix" match-url "$origin")
              count=$(printf '%s' "$matches" | grep -c . || true)
              [ "$count" -le 1 ] || die "$repo matches several inputs (''${matches//$'
      '/ }); pass --input NAME"
              if [ "$count" -eq 1 ]; then input=$(printf '%s' "$matches" | head -1); fi
            fi

            if [ -z "$input" ]; then
              echo "ship: $repo is in no finix input; pushed $branch ($rev)"
              exit 0
            fi

            lock_finix
            echo "ship: luin-pin update $input" >&2
            luin-pin -C "$finix" update "$input" 9>&-
            if git -C "$finix" diff --quiet -- .luin/pins.lock.json; then
              echo "ship: .luin/pins.lock.json already pins $input at $rev" >&2
            else
              git -C "$finix" commit -q -m "bump $input: $subject" -- .luin/pins.lock.json 9>&-
            fi

            switch_and_push_finix
            echo "ship: $input $rev -> finix $(git -C "$finix" rev-parse --short HEAD)"
    '';
  };
in {
  environment = {
    systemPackages = [nh ship];
    variables = {
      NH_FILE = "${config.user.homeDirectory}/finix/default.nix";
      NH_ATTRP = "nixosConfigurations.${config.networking.hostName}";
    };
  };
}
