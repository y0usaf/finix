{
  pkgs,
  inputPackages,
  ...
}: let
  luinPin = inputPackages.luin.luin-pin;
  ship = pkgs.writeShellApplication {
    name = "ship";
    runtimeInputs = [pkgs.git pkgs.jq pkgs.nix pkgs.util-linux inputPackages.nh.default luinPin];
    text = ''
      die() { echo "ship: $*" >&2; exit 1; }
      flake=''${NH_FLAKE:-$HOME/finix}
      remotes=''${SHIP_FINIX_REMOTES:-github forgejo}
      case "''${1:-}" in
        -h | --help)
          echo "usage: ship [REPO] [--input NAME]"
          exit 0
          ;;
      esac
      if git -C "$flake" rev-parse --git-dir >/dev/null 2>&1; then
        [ -z "$(git -C "$flake" status --porcelain --untracked-files=no)" ] || die "$flake has uncommitted changes"
      fi
      repo=$(realpath "''${1:-$PWD}")
      shift || true
      input=""
      if [ "''${1:-}" = "--input" ]; then
        input=''${2:-}
        [ -n "$input" ] || die "--input wants an input name"
        shift 2
      fi
      [ -d "$repo/.git" ] || die "$repo is not a git repository"
      dirty=$(git -C "$repo" status --porcelain --untracked-files=no)
      [ -z "$dirty" ] || die "$repo has uncommitted changes:
$dirty"
      branch=$(git -C "$repo" symbolic-ref --quiet --short HEAD) || die "$repo has a detached HEAD"
      rev=$(git -C "$repo" rev-parse HEAD)
      subject=$(git -C "$repo" log -1 --format=%s)

      if [ -f "$repo/.luin/pins.lock.json" ] && [ -f "$repo/default.nix" ]; then
        if nix eval --impure -f "$repo" --apply 'x: x ? checks && x.checks ? x86_64-linux' 2>/dev/null | grep -qx true; then
          echo "ship: nix build checks $repo" >&2
          nix build --impure --no-link -f "$repo" checks.x86_64-linux >&2
        fi
      elif [ -f "$repo/flake.nix" ]; then
        echo "ship: nix flake check $repo" >&2
        nix flake check --no-write-lock-file "$repo" >&2
      fi
      echo "ship: push $branch $rev" >&2
      git -C "$repo" push origin "HEAD:$branch" >&2

      if [ -z "$input" ]; then
        origin=$(git -C "$repo" remote get-url origin)
        matches=$(luin-pin -C "$flake" match-url "$origin")
        count=$(printf '%s' "$matches" | grep -c . || true)
        [ "$count" -le 1 ] || die "$repo matches several inputs (''${matches//$'\n'/ }); pass --input NAME"
        if [ "$count" -eq 1 ]; then input=$(printf '%s' "$matches" | head -1); fi
      fi

      if [ -z "$input" ]; then
        echo "ship: $repo is in no finix input; pushed $branch" >&2
        jq -nc --arg repo "$repo" --arg branch "$branch" --arg rev "$rev" --arg subject "$subject" \
          '{repo: $repo, branch: $branch, rev: $rev, subject: $subject, input: null, finix: null, switch: null}'
        exit 0
      fi

      echo "ship: luin-pin update $input" >&2
      luin-pin -C "$flake" update "$input" >&2
      if git -C "$flake" diff --quiet -- .luin/pins.lock.json; then
        echo "ship: .luin/pins.lock.json already pins $input at $rev" >&2
      else
        git -C "$flake" commit -q -m "bump $input: $subject" -- .luin/pins.lock.json
      fi
      finix_rev=$(git -C "$flake" rev-parse HEAD)
      switched=$(finix-switch | tail -1) || die "finix-switch failed"
      for remote in $remotes; do
        git -C "$flake" push "$remote" HEAD >&2 || die "cannot push $flake to $remote"
      done
      jq -nc --arg repo "$repo" --arg branch "$branch" --arg rev "$rev" --arg subject "$subject" --arg input "$input" \
        --arg finix "$finix_rev" --argjson switch "$switched" \
        '{repo: $repo, branch: $branch, rev: $rev, subject: $subject, input: $input, finix: $finix, switch: $switch}'
    '';
  };
in {
  environment.systemPackages = [ship];
}
