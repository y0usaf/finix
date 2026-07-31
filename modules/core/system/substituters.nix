{
  config = {
    nix.settings = {
      use-xdg-base-directories = true;
      # dead-cache stall tax when the finix server is off (default 15s x 5).
      connect-timeout = 5;
      # Dead/unreachable substituters degrade to a local build, not abort the run.
      fallback = true;
      # One attempt avoids ~40s stalls from default 5 retries x 5s timeout.
      download-attempts = 1;
      substituters = [
        # attic on the finix server: push cache for heavy local builds
        # (CUDA-class). LAN first, tailnet fallback when roaming.
        "http://192.168.2.66:8787/cache"
        "http://y0usaf-server:8787/cache"
        "https://chaotic-nyx.cachix.org"
        "https://nyx.cachix.org"
        "https://cuda-maintainers.cachix.org"
        "https://cache.nixos-cuda.org?priority=41"
        "https://nix-community.cachix.org"
        "https://nix-gaming.cachix.org"
      ];
      trusted-public-keys = [
        "cache:lPd94Ltnv0ZYpkoK5UtQi/VrGkEtHRT7Af6jUzy3PLA="
        "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
        "nyx.cachix.org-1:xH6G0MO9PrpeGe7mHBtj1WbNzmnXr7jId2mCiq6hipE="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      ];
      "extra-substituters" = [
        "https://nix-community.cachix.org"
        "https://cache.nixos-cuda.org/?priority=41"
      ];
      "extra-trusted-public-keys" = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };
  };
}
