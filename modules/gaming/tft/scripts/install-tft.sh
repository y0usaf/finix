#!/usr/bin/env bash
# Install Teamfight Tactics into the running Waydroid instance.
#
# TFT mobile is not directly exposed as a plain APK; it is distributed via
# Google Play. Waydroid's debloated builds don't ship GMS, so the normal
# route is Aurora Store (a Play-compatible client) inside the container.
#
# Steps:
#   1. Start the session (./scripts/session.sh).
#   2. In the Android UI, open Aurora Store (installed with the GAPPS image).
#   3. Sign in with a throwaway / Google account, search "Teamfight Tactics",
#      and install.
#
# If you already have a TFT APK on disk, install it directly:
#   waydroid app install ./tft.apk
set -euo pipefail

if [ "$#" -ge 1 ] && [ -f "$1" ]; then
  echo "[tft] Installing APK: $1"
  waydroid app install "$1"
else
  echo "[tft] No APK given."
  echo "  TFT is on Google Play. Open Aurora Store inside Waydroid and install"
  echo "  'Teamfight Tactics' from there."
  echo "  Or: ./scripts/install-tft.sh /path/to/tft.apk"
fi
