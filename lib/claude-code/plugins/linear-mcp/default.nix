# linear-mcp plugin - Linear API integration for Claude Code
#
# API key is automatically loaded from shell profile via ~/Tokens/LINEAR_API_KEY.txt
# (auto-loaded by the export_vars_from_files zsh function in lib/shell/zsh/export-vars.nix)
{
  name = "linear-mcp";
  version = "1.0.0";
  description = "Linear API integration for issue tracking and project management";
  author = {
    name = "y0usaf";
  };

  hooks = import ./hooks.nix;

  mcpServers = {
    linear = {
      command = "bunx";
      args = [
        "--bun"
        "@tacticlaunch/mcp-linear"
      ];
    };
  };
}
