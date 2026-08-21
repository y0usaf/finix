#!/usr/bin/env bash
# Boot the Waydroid Android container + session, then launch TFT directly.
#
# Persistence: /var/lib/waydroid is bind-mounted from /persist at boot
# (impermanence allowlist), so the image + userdata + apps survive reboot.
# libndk/houdini (ARM translation) are one-time setup already baked into the
# persisted image — not re-run here.
set -euo pipefail

WAYDROID="${WAYDROID:?set by module}"
LXC="${LXC:?set by module}"
ANDROID_TOOLS="${ANDROID_TOOLS:?set by module}"
export PATH="$WAYDROID/bin:$LXC/bin:$ANDROID_TOOLS/bin:$PATH"
export WAYDROID_EXTRA_ARGS="${WAYDROID_EXTRA_ARGS:---gpu-mode host}"

TFT_PACKAGE="${TFT_PACKAGE:-com.riotgames.league.teamfighttactics}"

# Prevent a second launcher from restarting or corrupting an active image download.
exec 9>/tmp/tft-launch.lock
if ! flock -n 9; then
  echo "[tft] another launch or initialization is already running." >&2
  exit 1
fi

# --- one-time init (the config is written before image downloads finish) ---
if [ ! -f /var/lib/waydroid/images/system.img ] \
    || [ ! -f /var/lib/waydroid/images/vendor.img ]; then
  echo "[tft] initializing Android images (first run, ~1.5GB)..."
  echo "[tft] keep this terminal open until both downloads finish."
  sudo env "PATH=$PATH" "WAYDROID_EXTRA_ARGS=$WAYDROID_EXTRA_ARGS" \
    waydroid init -f -s GAPPS
fi

if [ ! -f /var/lib/waydroid/images/system.img ] \
    || [ ! -f /var/lib/waydroid/images/vendor.img ]; then
  echo "[tft] Waydroid initialization did not produce complete images." >&2
  exit 1
fi

# --- Google Play device-spoof (Pixel 5 / redfin, Android 11) ---
# Idempotent: skips if the marker line is already present.
if ! sudo grep -qs '^ro.build.fingerprint=google/redfin' \
    /var/lib/waydroid/waydroid_base.prop; then
  echo "[tft] adding Google Pixel 5 device-spoof to waydroid_base.prop"
  sudo tee -a /var/lib/waydroid/waydroid_base.prop >/dev/null <<'EOF'
ro.product.brand=google
ro.product.manufacturer=Google
ro.system.build.product=redfin
ro.product.name=redfin
ro.product.device=redfin
ro.product.model=Pixel 5
ro.system.build.flavor=redfin-user
ro.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.system.build.description=redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys
ro.bootimage.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.build.display.id=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.build.tags=release-keys
ro.build.description=redfin-user 11 RQ3A.211001.001 eng.electr.20230318.111310 release-keys
ro.vendor.build.fingerprint=google/redfin/redfin:11/RQ3A.211001.001/eng.electr.20230318.111310:user/release-keys
ro.vendor.build.id=RQ3A.211001.001
ro.vendor.build.tags=release-keys
ro.vendor.build.type=user
ro.odm.build.tags=release-keys
EOF
fi

# --- clean any stale session/container so launch is idempotent ---
sudo -n waydroid session stop 2>/dev/null || true
sudo -n waydroid container stop 2>/dev/null || true

# --- container manager (root dbus service) ---
echo "[tft] starting container manager (root)..."
if ! sudo -n env "PATH=$PATH" "WAYDROID_EXTRA_ARGS=$WAYDROID_EXTRA_ARGS" \
     bash -c 'waydroid container start >/tmp/waydroid-container.log 2>&1 &'; then
  echo "container manager failed to start" >&2
  exit 1
fi
# wait for the dbus name
for _ in $(seq 1 30); do
  if dbus-send --system --print-reply --dest=org.freedesktop.DBus \
      /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null \
      | grep -q 'id.waydro.Container'; then
    break
  fi
  sleep 1
done

# --- tablet resolution so TFT picks the larger board layout ---
WD_TABLET_RES="${WD_TABLET_RES:-2560x1600}"
echo "[tft] Android display -> tablet $WD_TABLET_RES (override WD_TABLET_RES)"
sudo -n waydroid shell wm size "$WD_TABLET_RES" \
  || echo "  (wm size failed — set it manually)"

# --- high render density so TFT picks the high-res asset tier ---
WD_ANDROID_DENSITY="${WD_ANDROID_DENSITY:-320}"
if [ "$WD_ANDROID_DENSITY" != "0" ]; then
  echo "[tft] Android density -> $WD_ANDROID_DENSITY (set 0 to skip)"
  sudo -n waydroid shell wm density "$WD_ANDROID_DENSITY" \
    || echo "  (wm density failed — set it manually)"
fi

# --- launch TFT directly (starts the session as needed) ---
echo "[tft] launching $TFT_PACKAGE..."
exec waydroid app launch "$TFT_PACKAGE"
