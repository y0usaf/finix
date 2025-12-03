{
  # Legacy exports (for backwards compatibility during transition)
  instructions = import ./instructions.nix;
  settings = import ./settings.nix;
  commands = import ./commands.nix;
  mcp = import ./mcp.nix;
  skills = import ./skills;
  agents = import ./agents;
  hooks = import ./hooks;
  scripts = import ./scripts;

  # New plugin marketplace system
  plugins = import ./plugins;
  marketplace = import ./plugins/marketplace.nix;
}
