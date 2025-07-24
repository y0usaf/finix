{
  sources,
  system,
}: let
  # Consolidated overlays function
  mkOverlays = sources: [
    # Extended lib overlay with helper functions
    (import ../overlays/lib-extensions.nix)
    # Neovim nightly overlay
    (import sources.neovim-nightly-overlay)
    # Fast fonts overlay
    (import ../overlays/fast-fonts.nix sources)
  ];
in
  import sources.nixpkgs {
    inherit system;
    overlays = mkOverlays sources;
    config.allowUnfree = true;
    config.cudaSupport = true;
  }
