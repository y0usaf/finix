{
  settings = import ./settings.nix;
  instructions = import ./instructions.nix;

  # Plugin marketplace system
  plugins = import ./plugins;
  marketplace = import ./plugins/marketplace.nix;
}
