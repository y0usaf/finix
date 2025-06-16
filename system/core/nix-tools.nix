###############################################################################
# Core Nix Tools
# Essential Nix maintenance and development tools (always enabled)
# - alejandra: Nix code formatter
# - statix: Nix linter for best practices
# - deadnix: Dead code elimination for Nix
###############################################################################
{pkgs, ...}: {
  config = {
    ###########################################################################
    # Core System Packages
    ###########################################################################
    environment.systemPackages = with pkgs; [
      alejandra # Nix code formatter
      statix # Nix linter for best practices
      deadnix # Dead code elimination for Nix
    ];
  };
}
