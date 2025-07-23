sources: [
  # Extended lib overlay with helper functions
  (import ./lib-extensions.nix)

  # Neovim nightly overlay
  (import sources.neovim-nightly-overlay)

  # Fast fonts overlay
  (import ./fast-fonts.nix sources)
]
