sources: [
  # Extended lib overlay with helper functions
  (import ./lib-extensions.nix)

  # Neovim nightly overlay
  (import sources.neovim-nightly-overlay)

  # Fast fonts overlay
  (import ./fast-fonts.nix sources)

  # OBS plugins with pinned versions
  (import ./obs-plugins.nix sources)
]
