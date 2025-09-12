sources: [
  # Fast-Fonts overlay
  (import ./fast-fonts.nix sources)

  # Deepin cursor themes
  (import ./deepin-cursors.nix sources)

  # Neovim nightly overlay
  (import sources.neovim-nightly-overlay)

  # OBS plugins with pinned versions
  (import ./obs-plugins.nix sources)
]
