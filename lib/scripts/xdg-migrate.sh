#!/bin/bash
set -euo pipefail

# XDG Migration Script - AGGRESSIVE cleanup of dotfiles
# Run this after enabling XDG Base Directory support

HOME_DIR="$HOME"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-$USER}"

echo "🧹 Starting AGGRESSIVE XDG Base Directory migration..."
echo "⚠️  This will move/delete files from your home directory!"

# Create ALL necessary directories
echo "📁 Creating comprehensive XDG directories..."
mkdir -p "$XDG_CONFIG_HOME"/{git,gtk-3.0,gtk-2.0,zsh,docker,parallel,nvidia,npm/config,python,aws,pulse,java,android}
mkdir -p "$XDG_DATA_HOME"/{android,pyenv,npm,nimble,dotnet,cargo,rustup,go,gnupg,dvdcss,wine,zoom,gradle,pki,steam}
mkdir -p "$XDG_STATE_HOME"/{bash,zsh,less,python,keras}
mkdir -p "$XDG_CACHE_HOME"/{npm,zsh,nv,NuGetPackages,texlive}
mkdir -p "$XDG_RUNTIME_DIR/npm" 2>/dev/null || true

# Migrate bash history
if [[ -f "$HOME_DIR/.bash_history" && ! -f "$XDG_STATE_HOME/bash/history" ]]; then
  echo "🐚 Migrating bash history..."
  mv "$HOME_DIR/.bash_history" "$XDG_STATE_HOME/bash/history"
fi

# Migrate zsh history
if [[ -f "$HOME_DIR/.zsh_history" && ! -f "$XDG_STATE_HOME/zsh/history" ]]; then
  echo "🐚 Migrating zsh history..."
  mv "$HOME_DIR/.zsh_history" "$XDG_STATE_HOME/zsh/history"
fi

# Migrate zsh compdump
if [[ -f "$HOME_DIR/.zcompdump" && ! -f "$XDG_CACHE_HOME/zsh/zcompdump-${ZSH_VERSION:-unknown}" ]]; then
  echo "🐚 Migrating zsh compdump..."
  mv "$HOME_DIR/.zcompdump" "$XDG_CACHE_HOME/zsh/zcompdump-${ZSH_VERSION:-unknown}"
fi

# Migrate gitconfig (if not already moved by NixOS config rebuild)
if [[ -f "$HOME_DIR/.gitconfig" && ! -f "$XDG_CONFIG_HOME/git/config" ]]; then
  echo "🔧 Migrating git config..."
  mv "$HOME_DIR/.gitconfig" "$XDG_CONFIG_HOME/git/config"
fi

# Migrate GTK bookmarks
if [[ -f "$HOME_DIR/.gtk-bookmarks" && ! -f "$XDG_CONFIG_HOME/gtk-3.0/bookmarks" ]]; then
  echo "🔖 Migrating GTK bookmarks..."
  mv "$HOME_DIR/.gtk-bookmarks" "$XDG_CONFIG_HOME/gtk-3.0/bookmarks"
fi

# Migrate GTK-2 config
if [[ -f "$HOME_DIR/.gtkrc-2.0" && ! -f "$XDG_CONFIG_HOME/gtk-2.0/gtkrc" ]]; then
  echo "🎨 Migrating GTK-2 config..."
  mv "$HOME_DIR/.gtkrc-2.0" "$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
fi

# AGGRESSIVE FILE MOVES - Move everything we can
echo "🚀 AGGRESSIVE FILE MIGRATION MODE"

# Individual files to move
FILES_TO_MOVE=(
  ".wget-hsts:$XDG_DATA_HOME/wget-hsts"
  ".nvidia-settings-rc:$XDG_CONFIG_HOME/nvidia/settings"
  ".pulse-cookie:$XDG_CONFIG_HOME/pulse/cookie"
)

for file_mapping in "${FILES_TO_MOVE[@]}"; do
  src_file="${file_mapping%%:*}"
  dest_file="${file_mapping##*:}"
  
  if [[ -f "$HOME_DIR/$src_file" ]]; then
    echo "📄 Moving $src_file to $dest_file..."
    mkdir -p "$(dirname "$dest_file")"
    mv "$HOME_DIR/$src_file" "$dest_file"
  fi
done

# Directories to move - MUCH MORE AGGRESSIVE
DIRS_TO_MIGRATE=(
  ".docker:config:docker"
  ".gnupg:data:gnupg" 
  ".gradle:data:gradle"
  ".npm:config:npm"
  ".pki:data:pki"
  ".java:config:java"
  ".nv:cache:nv"
  ".bun:data:bun"
  ".minecraft:data:minecraft"
  ".steam:data:steam"
  ".local/share/Steam:data:Steam"
)

for dir_mapping in "${DIRS_TO_MIGRATE[@]}"; do
  IFS=':' read -r src_dir xdg_type dest_dir <<< "$dir_mapping"
  
  if [[ -d "$HOME_DIR/$src_dir" ]]; then
    case "$xdg_type" in
      "config") target_dir="$XDG_CONFIG_HOME/$dest_dir" ;;
      "data")   target_dir="$XDG_DATA_HOME/$dest_dir" ;;
      "cache")  target_dir="$XDG_CACHE_HOME/$dest_dir" ;;
      "state")  target_dir="$XDG_STATE_HOME/$dest_dir" ;;
      *) target_dir="$XDG_DATA_HOME/$dest_dir" ;;
    esac
    
    if [[ ! -e "$target_dir" ]]; then
      echo "📂 MOVING $src_dir to $target_dir..."
      mkdir -p "$(dirname "$target_dir")"
      mv "$HOME_DIR/$src_dir" "$target_dir"
    else
      echo "⚠️  Target exists: $target_dir - skipping $src_dir"
    fi
  fi
done

# Check for remaining problematic files/directories
echo "🔍 Checking for remaining problematic dotfiles..."
PROBLEM_ITEMS=(
  ".bash_history"
  ".zsh_history"
  ".gitconfig"
  ".gtk-bookmarks"
  ".gtkrc-2.0"
  ".docker"
  ".gnupg"
  ".gradle"
  ".npm"
  ".pki"
  ".java"
  ".zcompdump"
  ".wget-hsts"
  ".nvidia-settings-rc"
)

remaining_items=()
for item in "${PROBLEM_ITEMS[@]}"; do
  if [[ -e "$HOME_DIR/$item" ]]; then
    remaining_items+=("$item")
  fi
done

if [[ ${#remaining_items[@]} -eq 0 ]]; then
  echo "✅ Migration complete! No remaining problematic dotfiles found."
else
  echo "⚠️  The following items still need attention:"
  printf '  %s\n' "${remaining_items[@]}"
  echo "📝 You may need to handle these manually or they'll be cleaned up on next rebuild."
fi

echo "🎉 XDG migration finished!"
echo "💡 Run 'xdg-ninja' again to verify the cleanup was successful."