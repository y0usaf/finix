sources: [
  # Extended lib overlay with helper functions
  (import ./lib-extensions.nix)

  # Neovim nightly overlay
  (import sources.neovim-nightly-overlay)

  # OBS plugins with pinned versions
  (import ./obs-plugins.nix sources)
]
