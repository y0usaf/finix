{
  name = "nix-security-scanner";
  description = "Detect security issues in nix configurations";
  content = ''
    ---
    name: nix-security-scanner
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
}
