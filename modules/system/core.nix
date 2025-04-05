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
  profile,
  ...
}: {
  config = {
    ###########################################################################
    # Core System Settings
    # System identity and behavior configuration
    ###########################################################################
    system.stateVersion = profile.modules.system.stateVersion; # Ensures compatibility when upgrading.
    time.timeZone = profile.modules.system.timezone; # Set the system's time zone.
    networking.hostName = profile.modules.system.hostname; # Define the system's hostname.
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
        trusted-users = ["root" profile.modules.system.username];
        builders-use-substitutes = true;
        fallback = true;

        substituters = [
          "https://cache.nixos.org"
          "https://hyprland.cachix.org"
          "https://chaotic-nyx.cachix.org"
          "https://nyx.cachix.org"
          "https://cuda-maintainers.cachix.org"
          "https://nix-community.cachix.org"
          "https://nix-gaming.cachix.org"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
          "nyx.cachix.org-1:xH6G0MO9PrpeGe7mHBtj1WbNzmnXr7jId2mCiq6hipE="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        ];
      };
      extraOptions = "";
    };
  };
}
