#!/usr/bin/env bash
# One-shot (re-runnable) migration for granular home impermanence.
# Reflink-copies the persisted allowlist from live @config/@local mounts
# into /persist/home/y0usaf so the impermanence binds find data after the
# @config/@local mounts are removed.
#
# Usage: sudo ./migrate-granular-home.sh
# Re-run right before the migration reboot (apps closed) to refresh copies.
# Cheap: cp --reflink=always shares extents (same btrfs fs).
set -euo pipefail

USER_NAME=y0usaf
SRC="/home/$USER_NAME"
DST="/persist/home/$USER_NAME"
GROUP="$(id -gn "$USER_NAME")"

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
mountpoint -q /persist || { echo "/persist not mounted" >&2; exit 1; }
mountpoint -q "$SRC/.config" || echo "WARN: $SRC/.config not a mountpoint (already migrated?)"

CONFIG_DIRS=(
  age aws gcloud gh ngrok
  chromium librewolf net.imput.helium
  discord discordcanary vesktop Vencord Slack
  syncthing
  AionUi Claude Codex opencode manicode agent-harness pi-harness jcode crush phi
  obsidian obs-studio BambuStudio OrcaSlicer GIMP Pinta stoat-desktop
  qBittorrent nicotine slskd Logseq Ladybird epy cmus "GitHub Desktop"
  gws gws-inscend Frame intent herdr kopuz snowflake camset
  Cemu unity3d bolt-launcher Olympus
  dconf nix nushell ekko
)

SHARE_DIRS=(
  gnupg keyrings pki
  PrismLauncher ComfyUI bun vicinae cargo rustup npm containers opencode phi
  dolphin-emu yuzu sudachi Cemu shipofharkinian bolt-launcher lutris gale
  com.kesomannen.gale NexusMods.App osu wine skua-wine godot PixelOver balatroai
  Celeste CassetteBeasts Brotato Baba_Is_You "binding of isaac rebirth"
  HallsOfTorment YourOnlyMoveIsHUSTLE "Rocket League" "SteamWorld Heist"
  shapez.io lootplot love pokete hackerpg com.overboy.noobsarecoming
  "Noobs Are Coming (Save)" .renpy ".Wurst encryption" aspyr-media
  "Smart Code ltd" CO-E33_Save_Editor com.co-e33-save-editor.app
  TelegramDesktop whatsapp-for-linux wasistlos zoom stremio qBittorrent nicotine
  slskd qutebrowser Ladybird nvim mpd Anki2 komikku manga-tui zathura
  qalculate jrnl weechat zoxide waydroid handy com.pais.handy whisper-models
  FreeCAD Meltytech bambu-studio bambustudio orca-slicer Vial wootomation
  fonts icons sounds applications android jupyter mcp-trader music-get polybot
  rtk tirith vibe-kanban supermaven smassh superfile parllama charm crush claude
  piebald ai.piebald.desktop ai.opencode.desktop app.codeg jean com.jean.desktop
  com.panes.app
  com.vercel.cli com.vercel.token kopuz syncthing
)

STATE_DIRS=(
  zsh bash elvish nix nvim codex opencode agent-harness pi-harness
  pi-rs-parallel ekko-pi ekko-parallel syncthing wireplumber
  lazygit manzil bayt herdr sayl music-get NexusMods.App spicetify
  superfile vicinae weechat zap
)

install -d -o "$USER_NAME" -g "$GROUP" \
  "$DST" "$DST/.config" "$DST/.local" "$DST/.local/share" "$DST/.local/state"

copied=0 skipped=0
copy() {
  local rel="$1" src dst
  src="$SRC/$rel" dst="$DST/$rel"
  if [ ! -e "$src" ]; then
    skipped=$((skipped + 1))
    return
  fi
  rm -rf "$dst"
  cp -a --reflink=always "$src" "$dst"
  copied=$((copied + 1))
}

for d in "${CONFIG_DIRS[@]}"; do copy ".config/$d"; done
for d in "${SHARE_DIRS[@]}"; do copy ".local/share/$d"; done
for d in "${STATE_DIRS[@]}"; do copy ".local/state/$d"; done

echo "copied=$copied skipped(missing)=$skipped"
du -sh "$DST/.config" "$DST/.local/share" "$DST/.local/state"
