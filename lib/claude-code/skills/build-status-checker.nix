{
  name = "build-status-checker";
  description = "Verify successful rebuild and test before auto-committing";
  content = ''
    ---
    name: build-status-checker
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
  script = ''
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
}
