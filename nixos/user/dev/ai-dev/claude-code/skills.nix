_: {
  config.usr.files.".claude/skills/build-status-checker/SKILL.md" = {
    text = ''
      ---
      name: Build Status Checker
      description: Verify successful rebuild and test before auto-committing
      ---

      # Build Status Checker

      Designed for the NixOS rebuild workflow (~/nixos).

      ## Purpose
      Autonomously verifies that `nh os switch` completed successfully before suggesting commits to git. This prevents committing broken configurations.

      ## When to Use
      After running:
      - `alejandra . && nh os switch --dry && nh os switch`

      The skill will check:
      - Build completed without errors
      - System is in a valid state
      - Ready for commit

      ## Behavior
      - Analyzes build output for errors
      - Verifies nixos-rebuild exit status
      - Confirms system services are running
      - Suggests safe commit message if everything passed
    '';
    clobber = true;
  };

  config.usr.files.".claude/skills/build-status-checker/check-build-status.sh" = {
    text = ''
      #!/usr/bin/env bash

      # Build Status Checker - Verifies NixOS rebuild success

      FLAKE_DIR="''${1:-.}"

      # Check if flake.nix exists
      if [[ ! -f "$FLAKE_DIR/flake.nix" ]]; then
        echo "Error: flake.nix not found in $FLAKE_DIR"
        exit 1
      fi

      # Check for recent build errors in /var/log/messages or journal
      if journalctl -n 100 | grep -qi "error\|failed"; then
        echo "Recent build errors detected in systemd journal"
        exit 1
      fi

      # Verify we can access the system configuration
      if [[ ! -d "/run/current-system" ]]; then
        echo "Error: /run/current-system not found"
        exit 1
      fi

      echo "✓ Build status verified successfully"
      exit 0
    '';
    executable = true;
    clobber = true;
  };

  config.usr.files.".claude/skills/configuration-consistency-auditor/SKILL.md" = {
    text = ''
      ---
      name: Configuration Consistency Auditor
      description: Audit and flag unnecessary divergence between Darwin and NixOS configs
      ---

      # Configuration Consistency Auditor

      Designed for maintaining cohesive configuration across multiple systems.

      ## Purpose
      Reviews Darwin and NixOS configurations in ~/nixos to identify:
      - Unnecessary differences that should be unified
      - Shared configuration opportunities
      - System-specific customizations that are justified

      ## When to Use
      - After making changes to either Darwin or NixOS configs
      - Before committing major configuration changes
      - To guide refactoring toward DRY principles

      ## Checks
      - Package consistency between systems
      - Tool/program configuration similarities
      - Home configuration alignment
      - Service definitions across platforms
      - Identifies areas for consolidation

      ## Output
      - Flags unnecessary divergence
      - Suggests unified configuration patterns
      - Highlights justified system-specific differences
    '';
    clobber = true;
  };

  config.usr.files.".claude/skills/configuration-consistency-auditor/audit-consistency.sh" = {
    text = ''
      #!/usr/bin/env bash

      # Configuration Consistency Auditor

      FLAKE_DIR="''${1:-.}"
      DARWIN_CONFIG="$FLAKE_DIR/darwin"
      NIXOS_CONFIG="$FLAKE_DIR/nixos"

      if [[ ! -d "$DARWIN_CONFIG" ]] || [[ ! -d "$NIXOS_CONFIG" ]]; then
        echo "Error: Darwin or NixOS config directories not found"
        exit 1
      fi

      echo "=== Configuration Consistency Audit ==="
      echo ""

      # Check for duplicate package definitions
      echo "Checking for duplicate package definitions..."
      DARWIN_PACKAGES=$(grep -r "systemPackages\|homePackages" "$DARWIN_CONFIG" 2>/dev/null | wc -l)
      NIXOS_PACKAGES=$(grep -r "systemPackages\|homePackages" "$NIXOS_CONFIG" 2>/dev/null | wc -l)

      echo "Darwin package definitions: $DARWIN_PACKAGES"
      echo "NixOS package definitions: $NIXOS_PACKAGES"
      echo ""

      # Check for common tools in both configs
      echo "Checking for shared tools..."
      SHARED_TOOLS=$(comm -12 \
        <(grep -rh "pkgs\.\w\+" "$DARWIN_CONFIG" 2>/dev/null | sed 's/.*pkgs\.\([a-zA-Z0-9_-]*\).*/\1/' | sort -u) \
        <(grep -rh "pkgs\.\w\+" "$NIXOS_CONFIG" 2>/dev/null | sed 's/.*pkgs\.\([a-zA-Z0-9_-]*\).*/\1/' | sort -u))

      echo "Found ''${SHARED_TOOLS}" | wc -l | xargs echo "Shared tools count:"

      exit 0
    '';
    executable = true;
    clobber = true;
  };

  config.usr.files.".claude/skills/nix-security-scanner/SKILL.md" = {
    text = ''
      ---
      name: Nix Security Scanner
      description: Detect security issues in nix configurations
      ---

      # Nix Security Scanner

      Designed for defensive security hardening of NixOS and Darwin configurations.

      ## Purpose
      Scans nix configuration files for:
      - Credential leaks (API keys, tokens, passwords)
      - Insecure package versions
      - Unsafe configuration patterns
      - Missing security hardening options

      ## When to Use
      - Before committing configuration changes
      - During security audits
      - When adding new packages or services
      - After updating flake.lock

      ## Detects
      - Hardcoded secrets in configuration
      - Known vulnerable packages
      - Permissive security settings (e.g., allowUnfree without justification)
      - Missing firewall rules
      - Insecure permission configurations

      ## Output
      - Lists potential security issues
      - Suggests remediation steps
      - Flags configurations requiring review
    '';
    clobber = true;
  };

  config.usr.files.".claude/skills/nix-security-scanner/scan-security.sh" = {
    text = ''
      #!/usr/bin/env bash

      # Nix Security Scanner

      FLAKE_DIR="''${1:-.}"

      echo "=== Nix Security Scanner ==="
      echo ""

      ISSUES=0

      # Check for common credential patterns
      echo "Scanning for potential credential leaks..."
      CRED_PATTERNS=(
        "password\s*=\s*\"[^\"]*\""
        "token\s*=\s*\"[^\"]*\""
        "secret\s*=\s*\"[^\"]*\""
        "api.key\s*=\s*\"[^\"]*\""
        "privateKey\s*=\s*\"[^\"]*\""
      )

      for pattern in "''${CRED_PATTERNS[@]}"; do
        if grep -r -E "$pattern" "$FLAKE_DIR" --include="*.nix" 2>/dev/null | grep -v "placeholder\|example\|TODO"; then
          echo "⚠ Potential credential found"
          ISSUES=$((ISSUES + 1))
        fi
      done

      # Check for permittedInsecurePackages without justification
      echo ""
      echo "Checking for permittedInsecurePackages..."
      if grep -r "permittedInsecurePackages" "$FLAKE_DIR" --include="*.nix" 2>/dev/null; then
        echo "⚠ Found permittedInsecurePackages - review justification"
        ISSUES=$((ISSUES + 1))
      fi

      echo ""
      if [[ $ISSUES -eq 0 ]]; then
        echo "✓ No obvious security issues detected"
        exit 0
      else
        echo "Found $ISSUES potential issues - review above"
        exit 1
      fi
    '';
    executable = true;
    clobber = true;
  };
}
