{
  settings = import ./settings-defaults.nix;
  instructions = import ./instructions-text.nix;

  # Plugin marketplace system
  plugins = import ./plugins/default.nix;
  marketplace = import ./plugins/marketplace.nix;
}
