# Packaged by writeShellApplication; all processes belong to this private runtime.
preview_keep=no
if [ "${1:-}" = --keep-session ]; then
  preview_keep=yes
  shift
fi
preview_root=$(mktemp -d -t finix-ekko-zellij.XXXXXX)
preview_selected=${EKKO_CONFIG:-$EKKO_PREVIEW_PROFILE}
mkdir -p "$preview_root/config"
cp -- "$(dirname -- "$preview_selected")"/*.lisp "$preview_root/config/"
cp -- "$preview_selected" "$preview_root/config/init.lisp"
export XDG_RUNTIME_DIR=$preview_root EKKO_CONFIG=$preview_root/config/init.lisp
unset EKKO_SESSION_NAME
cleanup() {
  if [ "$preview_keep" = yes ] && [ -S "$preview_root/ekko-v2/preview.sock" ]; then
    printf 'Session retained in %s; use the printed Attach or Stop command.\n' "$preview_root" >&2
    return
  fi
  "$EKKO_PREVIEW_BINARY" stop preview >/dev/null 2>&1 || true
  rm -rf -- "$preview_root"
}
trap cleanup EXIT
printf 'Private preview config: %s\n' "$EKKO_CONFIG" >&2
printf 'Reload: XDG_RUNTIME_DIR=%q %q config reload preview\n' "$preview_root" "$EKKO_PREVIEW_BINARY" >&2
printf 'Attach: XDG_RUNTIME_DIR=%q %q attach preview\n' "$preview_root" "$EKKO_PREVIEW_BINARY" >&2
printf 'Stop: XDG_RUNTIME_DIR=%q %q stop preview\n' "$preview_root" "$EKKO_PREVIEW_BINARY" >&2
if [ "$#" -eq 0 ]; then
  set -- "${SHELL:-/bin/sh}" -i
fi
"$EKKO_PREVIEW_BINARY" run --session preview "$@"
