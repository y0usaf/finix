#!/usr/bin/env bash
# One-time Waydroid Android image setup.
# Downloads the Android system image (GAPPS variant for installing from
# Aurora Store / Play, ~1-2GB first time).
set -euo pipefail

echo "[init] Downloading Waydroid Android image (GAPPS variant)..."
waydroid init -f -s GAPPS
echo ""
echo "[init] Done."
echo "Next: start the session with ./scripts/session.sh"
