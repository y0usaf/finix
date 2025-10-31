{
  instructions = import ./instructions.nix;
  settings = import ./settings.nix;
  statusline = import ./statusline.nix;
  commands = import ./commands.nix;
  mcp = import ./mcp.nix;
  skills = import ./skills;
  agents = import ./agents;
  hooks = import ./hooks.nix;
}
