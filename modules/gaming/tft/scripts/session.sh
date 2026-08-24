#!/usr/bin/env bash
# Start the Waydroid container (root) + session (user) and show the Android UI.
# Run as the USER (not sudo): container start needs root, session needs your
# DISPLAY + session bus.
set -euo pipefail

WAYDROID="${WAYDROID:?set by module}"
LXC="${LXC:?set by module}"
ANDROID_TOOLS="${ANDROID_TOOLS:?set by module}"
export PATH="$WAYDROID/bin:$LXC/bin:$ANDROID_TOOLS/bin:$PATH"

TFT_HOUDINI_SCRIPT="${TFT_HOUDINI_SCRIPT:?set by module}"
bash "$TFT_HOUDINI_SCRIPT"

# --- clean any stale session/container so start is idempotent ---
sudo -n waydroid session stop 2>/dev/null || true
sudo -n waydroid container stop 2>/dev/null || true

# --- container manager (root dbus service) ---
echo "[session] Starting Waydroid container..."
# `waydroid container start` is the root DBus daemon: it exports
# id.waydro.Container and runs a main loop forever, so background it and wait
# for the name to appear (same pattern as launch.sh).
if ! sudo -n env "PATH=$PATH" \
     bash -c 'waydroid container start >/tmp/waydroid-container.log 2>&1 &'; then
  echo "container manager failed to start" >&2
  exit 1
fi
for _ in $(seq 1 30); do
  if dbus-send --system --print-reply --dest=org.freedesktop.DBus \
      /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
      | grep -q 'id.waydro.Container'; then
    break
  fi
  sleep 1
done

echo "[session] Starting Waydroid session (full UI)..."
waydroid show-full-ui || waydroid session start
