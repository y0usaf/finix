#!/usr/bin/env bash
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/omp-box"
grants="$state/grants"
shares="$state/shares"
key="$state/id_ed25519"
port=22422
target=y0usaf@127.0.0.1
ssh=(ssh -q -p "$port" -i "$key" -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o BatchMode=yes)

usage() {
  cat <<'EOF'
usage: omp-box <command>

  list [--json]        granted folders
  add PATH [--copy]    share PATH into the box at the same path
  rm NAME              revoke a grant
  reconcile            re-apply every grant (after a box restart)
EOF
}

up() { "${ssh[@]}" "$target" true 2>/dev/null; }

fail() { printf 'omp-box: %s\n' "$*" >&2; exit 1; }

covers() { local base=${1%/}; case "$2/" in "$base"/*) return 0 ;; *) return 1 ;; esac; }

mount_guest() {
  local name=$1 path=$2
  "${ssh[@]}" "$target" "set -e
    p=$(printf %q "$path")
    /run/wrappers/bin/sudo mkdir -p \"\$(dirname \"\$p\")\" \"\$p\"
    /run/wrappers/bin/sudo mountpoint -q \"\$p\" || /run/wrappers/bin/sudo mount --bind $(printf %q "/mnt/shares/$name") \"\$p\""
}

unmount_guest() {
  local path=$1
  "${ssh[@]}" "$target" "/run/wrappers/bin/sudo mountpoint -q $(printf %q "$path") && /run/wrappers/bin/sudo umount $(printf %q "$path") || true" 2>/dev/null || true
}

apply_host() {
  local name=$1 path=$2 mode=$3
  mkdir -p "$shares/$name"
  case $mode in
    copy) cp -au "$path/." "$shares/$name/" ;;
    bind) findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1 || /run/wrappers/bin/sudo -n mount --bind "$path" "$shares/$name" ;;
  esac
}

drop_host() {
  local name=$1 mode=$2
  if [ "$mode" = bind ]; then
    findmnt -n -o TARGET "$shares/$name" >/dev/null 2>&1 && /run/wrappers/bin/sudo -n umount "$shares/$name" || true
  fi
  rm -rf "${shares:?}/${name:?}"
}

cmd_add() {
  local path="" mode=bind
  while [ $# -gt 0 ]; do
    case $1 in
      --copy) mode=copy ;;
      *) path=$1 ;;
    esac
    shift
  done
  [ -n "$path" ] || fail "add needs a path"
  path=$(realpath -e -- "$path")
  [ -d "$path" ] || fail "$path is not a directory"
  if covers "$path" "$(realpath -m -- "$state")"; then fail "$path holds the share directory itself, so sharing it loops"; fi
  if covers "$path" "$HOME"; then fail "$path covers $HOME, where the box keeps its own state; share a folder inside it"; fi
  local name
  name=$(basename -- "$path" | tr -cd 'A-Za-z0-9._-')
  [ -e "$grants/$name" ] && fail "grant '$name' already exists (rm it first)"
  mkdir -p "$grants" "$shares"
  apply_host "$name" "$path" "$mode"
  printf '%s\t%s\n' "$path" "$mode" > "$grants/$name"
  if up; then mount_guest "$name" "$path" || fail "granted on the host, but the box did not take it"; fi
  printf '%s  %s  %s\n' "$name" "$mode" "$path"
}

cmd_rm() {
  local name=${1:-}
  [ -n "$name" ] || fail "rm needs a name"
  [ -e "$grants/$name" ] || fail "no grant '$name'"
  local path mode
  IFS=$'\t' read -r path mode < "$grants/$name"
  if up; then unmount_guest "$path"; fi
  drop_host "$name" "$mode"
  rm -f "$grants/$name"
  printf 'removed %s\n' "$name"
}

cmd_list() {
  local json=0
  [ "${1:-}" = --json ] && json=1
  if [ "$json" = 1 ]; then
    printf '['
    local first=1 name path mode
    for f in "$grants"/*; do
      [ -e "$f" ] || continue
      IFS=$'\t' read -r path mode < "$f"
      name=$(basename -- "$f")
      [ "$first" = 1 ] || printf ','
      first=0
      printf '{"name":"%s","path":"%s","mode":"%s"}' "$name" "$path" "$mode"
    done
    printf ']\n'
    return
  fi
  local name
  for f in "$grants"/*; do
    [ -e "$f" ] || continue
    local path mode
    IFS=$'\t' read -r path mode < "$f"
    name=$(basename -- "$f")
    printf '%-16s %-5s %s\n' "$name" "$mode" "$path"
  done
}

cmd_reconcile() {
  [ -d "$grants" ] || return 0
  local f path mode name
  for f in "$grants"/*; do
    [ -e "$f" ] || continue
    IFS=$'\t' read -r path mode < "$f"
    name=$(basename -- "$f")
    apply_host "$name" "$path" "$mode" && mount_guest "$name" "$path" ||
      printf 'omp-box: grant %s (%s) did not apply\n' "$name" "$path" >&2
  done
}

case ${1:-} in
  list) shift; cmd_list "$@" ;;
  add) shift; cmd_add "$@" ;;
  rm) shift; cmd_rm "$@" ;;
  reconcile) cmd_reconcile ;;
  *) usage; exit 2 ;;
esac
