#!/usr/bin/env bash
# Nix tools helper: Format, lint, and dead-code check Nix files
# Usage: nix-check.sh [format|lint|deadcode|all] [file.nix]

set -euo pipefail

file="${2:-.}"
action="${1:-all}"

if [[ ! -e "$file" ]] && [[ "$file" != "." ]]; then
  echo "Error: File or directory not found: $file" >&2
  exit 1
fi

# Check tool availability
check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo "Warning: $1 not found in PATH" >&2
    return 1
  fi
  return 0
}

format() {
  local target="$1"
  if ! check_tool alejandra; then return 1; fi
  if [[ -d "$target" ]]; then
    echo "Formatting all .nix files in $target..."
    alejandra "$target" || true
  else
    echo "Formatting $target..."
    alejandra "$target" || true
  fi
}

lint() {
  local target="$1"
  if ! check_tool statix; then return 1; fi
  if [[ -d "$target" ]]; then
    echo "Linting all .nix files in $target..."
    statix check "$target" 2>&1 | grep -E '(warning|error):' || echo "No statix issues found"
  else
    echo "Linting $target..."
    statix check "$target" 2>&1 | grep -E '(warning|error):' || echo "No statix issues found"
  fi
}

deadcode() {
  local target="$1"
  if ! check_tool deadnix; then return 1; fi
  if [[ -d "$target" ]]; then
    echo "Checking for dead code in $target..."
    deadnix -f "$target" 2>&1 | grep -v '^$' || echo "No dead code found"
  else
    echo "Checking for dead code in $target..."
    deadnix -f "$target" 2>&1 | grep -v '^$' || echo "No dead code found"
  fi
}

case "$action" in
  format)
    format "$file"
    ;;
  lint)
    lint "$file"
    ;;
  deadcode)
    deadcode "$file"
    ;;
  all)
    format "$file"
    echo "---"
    lint "$file"
    echo "---"
    deadcode "$file"
    ;;
  *)
    echo "Usage: nix-check.sh [format|lint|deadcode|all] [file/dir]" >&2
    echo "  format:  Run alejandra to format Nix files" >&2
    echo "  lint:    Run statix to check for lint issues" >&2
    echo "  deadcode: Run deadnix to find unused code" >&2
    echo "  all:     Run all checks" >&2
    exit 1
    ;;
esac
