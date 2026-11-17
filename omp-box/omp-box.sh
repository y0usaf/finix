#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/omp-box"
grants="$state/grants"
shares="$state/shares"
meta="$state/meta"
manifest="$meta/manifest"
key="$state/ssh-key"
port=22422
target=y0usaf@127.0.0.1
ssh=(ssh -q -p "$port" -i "$key" -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o BatchMode=yes -o ConnectTimeout=2 -o ServerAliveInterval=2 -o ServerAliveCountMax=1)

usage() {
  cat <<'EOF'
usage: omp-box [OMP ARGS...]   run omp in the box, in this folder
       omp-box <command>

  list [--json]        granted folders
  add PATH [--copy | --ro] [--name NAME] [--as USER]
                       share PATH into the box as grant NAME (default: PATH's
                       folder name); --copy shares a copy, --ro shares it
                       read-only, --as gives it to that box user only (default:
                       the box's own user), which is how a bot gets a folder
  rm NAME              revoke a grant
  reconcile            re-apply every grant (after a box restart)
  retry                start the box again after omp-box-run gave up on it
EOF
}

# The box is ready once its root-run share service has mounted what the grants name.
up() { "${ssh[@]}" -o ConnectTimeout=1 "$target" "test -e /run/omp-box/ready" 2>/dev/null; }

fail() { printf 'omp-box: %s\n' "$*" >&2; exit 1; }

covers() { local base=${1%/}; case "$2/" in "$base"/*) return 0 ;; *) return 1 ;; esac; }

# Where a grant appears in the box: paths inside the user's home keep their place under it, so a bot's folder
# shows up in the bot's own home and nowhere else. The user's own sessions may also name any absolute path.
box_target() {
  local path=$1 who=$2 tilde='~'
  case $path in
    "$HOME") printf '%s' "$tilde" ;;
    "$HOME"/*) printf '%s/%s' "$tilde" "${path#"$HOME"/}" ;;
    *) [ "$who" = "$target_user" ] || return 1; printf '%s' "$path" ;;
  esac
}

target_user=${target%@*}

apply_host() {
  local name=$1 path=$2 mode=$3
  mkdir -p "$shares/$name"
  case $mode in
    copy) cp -au "$path/." "$shares/$name/" ;;
    bind) if ! findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1; then /run/wrappers/bin/sudo -n mount --bind "$path" "$shares/$name"; fi ;;
    ro) if ! findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1; then /run/wrappers/bin/sudo -n mount --bind "$path" "$shares/$name"; fi; if test -w "$shares/$name"; then /run/wrappers/bin/sudo -n mount -o remount,bind,ro "$shares/$name"; fi ;;
  esac
  # Nothing here touches the shared files: a bot in the box is another Unix user, and it works in the folder through
  # a view that makes the host user's files its own (omp-box/guest.nix), so the host's modes stay the host's own and
  # no file is rewritten for the box's benefit.
}

# What each user gets, one `user grant target flags` line per grant, read by the box's own root-run service: the
# box mounts every folder as root when it runs and when this file changes, so no guest user ever needs to mount
# anything, and a bot sees exactly the targets this file names for it.
write_manifest() {
  local f name path mode who tmp
  mkdir -p "$meta"
  # The guest maps a granted folder to the bot it was granted to by the uid the folder's files belong to here, so it
  # needs that uid beside the grants (omp-box/guest.nix, shareApply).
  id -u >"$meta/host-uid"
  tmp=$(mktemp "$meta/.manifest.XXXXXX")
  for f in "$grants"/*; do
    [ -e "$f" ] || continue
    IFS=$'\t' read -r path mode who < "$f"
    name=$(basename -- "$f")
    who=${who:-$target_user}
    if ! box_target "$path" "$who" >/dev/null; then
      printf 'omp-box: grant %s (%s) is outside %s and does not belong to the box user\n' "$name" "$path" "$HOME" >&2
      continue
    fi
    printf '%s\t%s\t%s\t%s\n' "$who" "$name" "$(box_target "$path" "$who")" "$mode" >>"$tmp"
  done
  chmod 644 "$tmp"
  mv -f "$tmp" "$manifest"
}

drop_host() {
  local name=$1 mode=$2
  if [ "$mode" != copy ]; then
    if findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1; then /run/wrappers/bin/sudo -n umount "$shares/$name" || fail "could not unmount $shares/$name, so the grant stays"; fi
  fi
  findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1 || rm -rf "${shares:?}/${name:?}"
}

cmd_add() {
  local path="" mode=bind name="" who=$target_user
  while [ $# -gt 0 ]; do
    case $1 in
      --copy) mode=copy ;;
      --ro) mode=ro ;;
      --name) name=${2:-}; shift ;;
      --as) who=${2:-}; shift ;;
      *) path=$1 ;;
    esac
    shift
  done
  [ -n "$path" ] || fail "add needs a path"
  [ -n "$who" ] || fail "--as needs a user"
  path=$(realpath -e -- "$path")
  [ -d "$path" ] || fail "$path is not a directory"
  if covers "$path" "$(realpath -m -- "$state")"; then fail "$path holds the share directory itself, so sharing it loops"; fi
  if covers "$path" "$HOME"; then fail "$path covers $HOME, where the box keeps its own state; share a folder inside it"; fi
  box_target "$path" "$who" >/dev/null || fail "$path is outside $HOME, so only the box's own user can be given it, not $who"
  [ -n "$name" ] || name=$(basename -- "$path")
  name=$(printf %s "$name" | tr -cd 'A-Za-z0-9._-')
  [ -n "$name" ] || fail "the grant needs a name of letters, digits, '.', '_' or '-'"
  [ -e "$grants/$name" ] && fail "grant '$name' already exists (rm it first)"
  mkdir -p "$grants" "$shares"
  apply_host "$name" "$path" "$mode"
  printf '%s\t%s\t%s\n' "$path" "$mode" "$who" > "$grants/$name"
  write_manifest
  printf '%s  %s  %s  %s\n' "$name" "$mode" "$who" "$path"
}

cmd_rm() {
  local name=${1:-}
  [ -n "$name" ] || fail "rm needs a name"
  [ -e "$grants/$name" ] || fail "no grant '$name'"
  local path mode who
  IFS=$'\t' read -r path mode who < "$grants/$name"
  drop_host "$name" "$mode"
  rm -f "$grants/$name"
  write_manifest
  printf 'removed %s\n' "$name"
}

cmd_list() {
  local json=0
  [ "${1:-}" = --json ] && json=1
  if [ "$json" = 1 ]; then
    printf '['
    local first=1 name path mode who
    for f in "$grants"/*; do
      [ -e "$f" ] || continue
      IFS=$'\t' read -r path mode who < "$f"
      who=${who:-$target_user}
      name=$(basename -- "$f")
      [ "$first" = 1 ] || printf ','
      first=0
      printf '{"name":"%s","path":"%s","mode":"%s","user":"%s","target":"%s"}' "$name" "$path" "$mode" "$who" "$(box_target "$path" "$who" || printf '%s' "$path")"
    done
    printf ']\n'
    return
  fi
  local name path mode who
  for f in "$grants"/*; do
    [ -e "$f" ] || continue
    IFS=$'\t' read -r path mode who < "$f"
    who=${who:-$target_user}
    name=$(basename -- "$f")
    printf '%-18s %-4s %-8s %-28s %s\n' "$name" "$mode" "$who" "$(box_target "$path" "$who" || printf '%s' "$path")" "$path"
  done
}

cmd_reconcile() {
  write_manifest
  [ -d "$grants" ] || return 0
  local f path mode name failed=0
  for f in "$grants"/*; do
    [ -e "$f" ] || continue
    IFS=$'\t' read -r path mode who < "$f"
    [ -d "$path" ] || continue
    name=$(basename -- "$f")
    apply_host "$name" "$path" "$mode" || {
      printf 'omp-box: grant %s (%s) did not apply\n' "$name" "$path" >&2
      failed=1
    }
  done
  if up; then :; else printf 'omp-box: the box is not up; it applies the grants when it boots\n' >&2; fi
  return "$failed"
}

cmd_retry() {
  local file="$state/status.json"
  [ -e "$file" ] || fail "the box is not waiting on a failure (no $file)"
  jq -e '.state == "failed"' "$file" >/dev/null || fail "the box is not failed: $file says $(jq -r .state "$file")"
  rm -f "$file"
  printf 'cleared %s, so omp-box-run starts the box again\n' "$file"
}

case ${1:-} in
  list) shift; cmd_list "$@" ;;
  add) shift; cmd_add "$@" ;;
  rm) shift; cmd_rm "$@" ;;
  reconcile) cmd_reconcile ;;
  retry) cmd_retry ;;
  -h | --help | help) usage ;;
  *) exec "$boxed" "$@" ;;
esac
