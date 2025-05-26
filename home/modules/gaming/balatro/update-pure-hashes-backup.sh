#!/usr/bin/env bash
# Script to update hashes for pure mode Balatro mods

set -euo pipefail

echo "Updating Balatro mod hashes for pure mode..."

# Function to get latest commit hash
get_latest_commit() {
    local owner="$1"
    local repo="$2"
    local branch="${3:-main}"
    curl -s "https://api.github.com/repos/$owner/$repo/commits/$branch" | jq -r '.sha'
}

# Function to get GitHub repo hash
get_github_hash() {
    local owner="$1"
    local repo="$2"
    local rev="$3"
    nix-shell -p nix-prefetch-github --run "nix-prefetch-github $owner $repo --rev $rev" | jq -r '.hash'
}

# Function to get file hash
get_file_hash() {
    local url="$1"
    nix-prefetch-url "$url"
}

echo "Getting latest commit hashes..."

# Get latest commits
STEAMODDED_REV=$(get_latest_commit "Steamodded" "smods")
TALISMAN_REV=$(get_latest_commit "SpectralPack" "Talisman")
CRYPTID_REV=$(get_latest_commit "SpectralPack" "Cryptid")
MULTIPLAYER_REV=$(get_latest_commit "Balatro-Multiplayer" "BalatroMultiplayer")
CARDSLEEVES_REV=$(get_latest_commit "larswijn" "CardSleeves")

echo "Getting SHA256 hashes..."

# Get hashes
STEAMODDED_HASH=$(get_github_hash "Steamodded" "smods" "$STEAMODDED_REV")
TALISMAN_HASH=$(get_github_hash "SpectralPack" "Talisman" "$TALISMAN_REV")
CRYPTID_HASH=$(get_github_hash "SpectralPack" "Cryptid" "$CRYPTID_REV")
MULTIPLAYER_HASH=$(get_github_hash "Balatro-Multiplayer" "BalatroMultiplayer" "$MULTIPLAYER_REV")
CARDSLEEVES_HASH=$(get_github_hash "larswijn" "CardSleeves" "$CARDSLEEVES_REV")

# Get file hashes
MORESPEEDS_HASH=$(get_file_hash "https://raw.githubusercontent.com/Steamodded/examples/refs/heads/master/Mods/MoreSpeeds.lua")
OVERLAY_HASH=$(get_file_hash "https://raw.githubusercontent.com/cantlookback/BalatrOverlay/refs/heads/main/balatroverlay.lua")

echo ""
echo "=== UPDATE mods-pure.nix WITH THESE VALUES ==="
echo ""
echo "steamodded:"
echo "  rev = \"$STEAMODDED_REV\";"
echo "  sha256 = \"$STEAMODDED_HASH\";"
echo ""
echo "talisman:"
echo "  rev = \"$TALISMAN_REV\";"
echo "  sha256 = \"$TALISMAN_HASH\";"
echo ""
echo "cryptid:"
echo "  rev = \"$CRYPTID_REV\";"
echo "  sha256 = \"$CRYPTID_HASH\";"
echo ""
echo "multiplayer:"
echo "  rev = \"$MULTIPLAYER_REV\";"
echo "  sha256 = \"$MULTIPLAYER_HASH\";"
echo ""
echo "cardsleeves:"
echo "  rev = \"$CARDSLEEVES_REV\";"
echo "  sha256 = \"$CARDSLEEVES_HASH\";"
echo ""
echo "morespeeds:"
echo "  sha256 = \"$MORESPEEDS_HASH\";"
echo ""
echo "overlay:"
echo "  sha256 = \"$OVERLAY_HASH\";"
echo ""
echo "Done! Update mods-pure.nix with these values and rebuild your system."