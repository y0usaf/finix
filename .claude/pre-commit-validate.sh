#!/usr/bin/env bash
# Pre-commit/pre-switch validation for entire nixos/ codebase
# Runs alejandra (auto-format), statix (lint), and deadnix (dead code)
# Blocks if formatting changes are made or lint issues found
# Exit codes:
#   0 = all clear, safe to proceed
#   1 = alejandra made changes, re-stage required
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
echo -e "${BLUE}Pre-Commit Validation: nixos/ Codebase${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"

# Track if we found any issues
format_issues=0
lint_issues=0
deadcode_issues=0

# 1. Run alejandra
echo -e "\n${BLUE}[1/3]${NC} Formatting check with alejandra..."
if ! check_tool alejandra; then
  echo -e "${GRAY}Skipping formatting check${NC}"
elif ! alejandra --check nixos/ 2>/dev/null; then
  echo -e "${YELLOW}⚠️  Formatting issues found, auto-fixing...${NC}"
  alejandra nixos/ 2>&1 | tail -5
  format_issues=1
  echo -e "${YELLOW}✓ Files formatted. You must re-stage changes.${NC}"
else
  echo -e "${GREEN}✓ All files properly formatted${NC}"
fi

# 2. Run statix
echo -e "\n${BLUE}[2/3]${NC} Linting check with statix..."
if ! check_tool statix; then
  echo -e "${GRAY}Skipping lint check${NC}"
else
  statix_output=$(statix check nixos/ 2>&1 || true)
  if echo "$statix_output" | grep -qE '(error|warning):'; then
    echo -e "${RED}✗ Lint issues found:${NC}"
    echo "$statix_output" | grep -E '(error|warning):' | head -20
    lint_issues=1
  else
    echo -e "${GREEN}✓ No lint issues${NC}"
  fi
fi

# 3. Run deadnix
echo -e "\n${BLUE}[3/3]${NC} Dead code check with deadnix..."
if ! check_tool deadnix; then
  echo -e "${GRAY}Skipping dead code check${NC}"
else
  deadnix_output=$(deadnix -f nixos/ 2>&1 || true)
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

if [[ $format_issues -eq 1 ]]; then
  echo -e "${YELLOW}⚠️  BLOCKED: Format changes detected${NC}"
  echo -e "   Run: ${BLUE}git add .${NC} (or review changes first)"
  echo -e "   Then: ${BLUE}git commit${NC} again or ${BLUE}nh os switch${NC}"
  exit 1
fi

if [[ $lint_issues -eq 1 ]] || [[ $deadcode_issues -eq 1 ]]; then
  echo -e "${RED}✗ BLOCKED: Lint/dead-code issues found${NC}"
  echo -e "   Fix issues manually and try again"
  exit 2
fi

echo -e "${GREEN}✓ All checks passed! Safe to proceed.${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
exit 0
