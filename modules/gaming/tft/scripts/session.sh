#!/usr/bin/env bash
# Start the Waydroid container (root) + session (user) and show the Android UI.
# Run as the USER (not sudo): container start needs root, session needs your
# DISPLAY + session bus.
set -euo pipefail

WAYDROID="${WAYDROID:?set by module}"
LXC="${LXC:?set by module}"
ANDROID_TOOLS="${ANDROID_TOOLS:?set by module}"
export PATH="$WAYDROID/bin:$LXC/bin:$ANDROID_TOOLS/bin:$PATH"

echo "[session] Starting Waydroid container..."
sudo -n env "PATH=$PATH" waydroid container start

echo "[session] Starting Waydroid session (full UI)..."
waydroid show-full-ui || waydroid session start
