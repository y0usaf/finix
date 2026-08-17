#!/usr/bin/env bash
# Bump TFT graphics to high/ultra + FPS unlock, by editing Game.cfg.
#
# TFT's quality knobs are under [Performance]; current default is "2" (med).
# Map: 0=Low 1=Med 2=High 4=Ultra. Resolution is separate (launch.sh `wm size`
# tablet 2560x1600). Requires TFT to be CLOSED (it rewrites this file on exit).
set -euo pipefail

CFG=/data/data/com.riotgames.league.teamfighttactics/no_backup/Config/Game.cfg
QUAL="${TFT_QUALITY:-4}"
WDB="$(command -v waydroid)"

if sudo "$WDB" shell -- ps -A 2>/dev/null | grep -q 'com.riotgames.league.teamfighttactics'; then
  echo "[tune] TFT is RUNNING — close it first or it overwrites the edit." >&2
  exit 1
fi

echo "[tune] backup -> Game.cfg.bak"
sudo "$WDB" shell -- cp "$CFG" "$CFG.bak"

# build one sed script (single token, no spaces) applied as separate argv
SED=""
for kw in MobileShadowQuality MobileEnvironmentQuality MobileEffectsQuality \
          MobileCharacterQuality MobileBackBufferScale ShadowQuality \
          EnvironmentQuality EffectsQuality CharacterQuality; do
  SED+="s/${kw}=.*/${kw}=${QUAL}/;"
done
SED+="s/EnableMobileFXAA=.*/EnableMobileFXAA=1/;"
SED+="s/EnableFXAA=.*/EnableFXAA=1/;"
SED+="s/WaitForVerticalSync=.*/WaitForVerticalSync=1/;"
SED+="s/FrameCapType=.*/FrameCapType=0/"

echo "[tune] quality -> $QUAL, FXAA on, framecap 0"
sudo "$WDB" shell -- sed -i "$SED" "$CFG"
echo "[tune] done. Relaunch TFT; revert:"
echo "  sudo waydroid shell -- cp $CFG.bak $CFG"
