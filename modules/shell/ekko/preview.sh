#!/usr/bin/env bash
# A disposable session; cleanup is confined to this private runtime directory.
set -euo pipefail
preview_binary=${1:-/tmp/finix-ekko-preview/bin/ekko}
preview_config=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/init.lisp
preview_runtime=$(mktemp -d -t finix-ekko-preview.XXXXXX)
export XDG_RUNTIME_DIR=$preview_runtime EKKO_CONFIG=$preview_config
unset EKKO_SESSION_NAME
cleanup() {
  "$preview_binary" stop preview >/dev/null 2>&1 || true
  rm -rf -- "$preview_runtime"
}
trap cleanup EXIT
"$preview_binary" run --session preview "${SHELL:-/bin/sh}" -i
