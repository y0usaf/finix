###############################################################################
# Core System Configuration Module
# Basic system identity and behavior configuration:
# - System version and compatibility
# - Time zone
# - Hostname
# - Package permissions
# - Nix package management
###############################################################################
{
  config,
  lib,
  pkgs,
  hostSystem,
  hostHome,
  ...
}: {
  config = {
    ###########################################################################
    # Core System Settings
    # System identity and behavior configuration
    ###########################################################################
    system.stateVersion = hostSystem.cfg.system.stateVersion; # Ensures compatibility when upgrading.
    time.timeZone = hostSystem.cfg.system.timezone; # Set the system's time zone.
    networking.hostName = hostSystem.cfg.system.hostname; # Define the system's hostname.
    nixpkgs.config.allowUnfree = true; # Allow installation of unfree (proprietary) packages.

    ###########################################################################
    # Nix-LD Configuration
    # Support for running dynamically linked executables
    ###########################################################################
    programs.nix-ld.enable = true;

    ###########################################################################
    # Nix Package Management
    # Package manager configuration for performance and caching
    ###########################################################################
    nix = {
      package = pkgs.nixVersions.stable;
      settings = {
        auto-optimise-store = true;
        max-jobs = "auto";
        cores = 0;
        experimental-features = ["nix-command" "flakes"];
        sandbox = true;
        trusted-users = ["root" hostSystem.cfg.system.username];
        builders-use-substitutes = true;
        fallback = true;

        substituters = [
          "https://cache.nixos.org"

        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="

        ];
      };
      extraOptions = "";
    };
  };
}
