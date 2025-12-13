{
  # Legacy exports (for backwards compatibility during transition)
  instructions = import ./instructions.nix;
  settings = import ./settings.nix;
  mcp = import ./mcp.nix;
  skills = import ./skills;
  agents = import ./agents;
  scripts = import ./scripts;

  # New plugin marketplace system
  plugins = import ./plugins;
  marketplace = import ./plugins/marketplace.nix;
}
