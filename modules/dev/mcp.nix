#===============================================================================
#                🔍 Model Context Protocol Configuration 🔍
#===============================================================================
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  config = {
    # Ensure npm is installed
    home.packages = with pkgs; [
      nodejs_20
    ];

    # Install MCP Brave Search server via npm
    home.activation.installMCP = lib.hm.dag.entryAfter ["npmSetup"] ''
      # Install Model Context Protocol server for Brave Search globally via npm
      ${pkgs.nodejs_20}/bin/npm install -g @modelcontextprotocol/server-brave-search
    '';

    # Add npm bin directory to PATH to ensure MCP server is accessible
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];
  };
}
