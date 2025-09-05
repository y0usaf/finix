{
  config = {
    nix.settings = {
      # Move cache out of userland to system directory
      cache-dir = "/var/cache/nix";

      # Build performance optimizations
      max-jobs = "auto";
      cores = 0; # Use all available cores per job

      # Store optimizations
      auto-optimise-store = true;
    };

    # Garbage collection configuration
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
}
