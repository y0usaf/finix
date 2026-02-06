{
  settings = import ./settings.nix;

  # Plugin marketplace system
  plugins = import ./plugins;
  marketplace = import ./plugins/marketplace.nix;
}
