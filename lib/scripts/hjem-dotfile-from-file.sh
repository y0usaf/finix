#!/usr/bin/env bash
# hjem-dotfile-from-file.sh
# Usage: ./hjem-dotfile-from-file.sh <source-file> <dotfile-path>
# Example: ./hjem-dotfile-from-file.sh ~/.zshrc .zshrc
# Example: ./hjem-dotfile-from-file.sh ~/.config/discordcanary/settings.json .config/discordcanary/settings.json

set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <source-file> <dotfile-path>"
  exit 1
fi

SRC_FILE="$1"
DOTFILE_PATH="$2" # e.g. .config/discordcanary/settings.json

if [ ! -f "$SRC_FILE" ]; then
  echo "Source file $SRC_FILE does not exist."
  exit 2
fi

# Update path to point to the new dotfiles directory structure
OUT_DIR="$(dirname "$0")/../../dotfiles/$(dirname "$DOTFILE_PATH" | sed 's/^\.//')"
OUT_FILE="$(basename "$DOTFILE_PATH").nix"
mkdir -p "$OUT_DIR"

# Read file contents and escape for Nix multi-line string
FILE_CONTENTS=$(sed 's/\\/\\\\/g; s/\$/\\$/g; s/"/\\"/g' "$SRC_FILE")

cat > "$OUT_DIR/$OUT_FILE" <<EOF
{
  "$DOTFILE_PATH".text = """
$FILE_CONTENTS
""";
}
EOF

echo "Generated $OUT_DIR/$OUT_FILE for Hjem dotfile management."
echo ""
echo "To use this dotfile in Hjem, just keep it in the dotfiles folder structure."