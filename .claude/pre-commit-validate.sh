#!/usr/bin/env bash
# Pre-commit/pre-switch validation for changed .nix files
# Runs statix (lint) and deadnix (dead code) on only files with uncommitted changes
# Note: Alejandra auto-format is handled by PostToolUse hooks on every edit
# Blocks if lint issues found
# Exit codes:
#   0 = all clear, safe to proceed
#   2 = lint/dead-code issues found, manual fixes required

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)" || {
  echo "Error: Not in a git repository" >&2
  exit 2
}

cd "$repo_root"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m'

# Check tool availability
check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${GRAY}⊘${NC} $1 not found in PATH (skipping)"
    return 1
  fi
  return 0
}

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}Pre-Commit Validation: Changed Files${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Get changed .nix files (staged + unstaged)
changed_files=$(git diff --name-only HEAD 2>/dev/null | grep '\.nix$' || echo "")

if [[ -z "$changed_files" ]]; then
  echo -e "${GREEN}✓ No .nix files changed, validation skipped${NC}"
  exit 0
fi

echo -e "Checking $(echo "$changed_files" | wc -l) changed .nix files:\n$(echo "$changed_files" | sed 's/^/  /')\n"

# Track if we found any issues
lint_issues=0
deadcode_issues=0

# Note: Alejandra is skipped here because PostToolUse already runs it on every edit
# Running it again would duplicate work and slow down pre-commit

# 1. Run statix on changed files
echo -e "${BLUE}[1/2]${NC} Linting check with statix..."
if ! check_tool statix; then
  echo -e "${GRAY}Skipping lint check${NC}"
else
  statix_output=$(echo "$changed_files" | xargs statix check 2>&1 || true)
  if echo "$statix_output" | grep -qE '(error|warning):'; then
    echo -e "${RED}✗ Lint issues found:${NC}"
    echo "$statix_output" | grep -E '(error|warning):' | head -20
    lint_issues=1
  else
    echo -e "${GREEN}✓ No lint issues${NC}"
  fi
fi

# 2. Run deadnix on changed files
echo -e "\n${BLUE}[2/2]${NC} Dead code check with deadnix..."
if ! check_tool deadnix; then
  echo -e "${GRAY}Skipping dead code check${NC}"
else
  deadnix_output=$(echo "$changed_files" | xargs deadnix -f 2>&1 || true)
  if echo "$deadnix_output" | grep -qE '(Warning|Error):'; then
    echo -e "${RED}✗ Unused code found:${NC}"
    echo "$deadnix_output" | grep -E '(Warning|Error):' | head -20
    deadcode_issues=1
  else
    echo -e "${GREEN}✓ No dead code detected${NC}"
  fi
fi

# Summary and exit
echo -e "\n${BLUE}════════════════════════════════════════${NC}"

if [[ $lint_issues -eq 1 ]] || [[ $deadcode_issues -eq 1 ]]; then
  echo -e "${RED}✗ BLOCKED: Lint/dead-code issues found${NC}"
  echo -e "   Fix issues in the changed files and try again"
  exit 2
fi

echo -e "${GREEN}✓ All checks passed! Safe to proceed.${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
exit 0
