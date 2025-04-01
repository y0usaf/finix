###############################################################################
# Cursor IDE Module
# Provides the Cursor AI-powered code editor
# - Modern code editor with AI features
# - Built on VSCode with additional AI features
# - Supports pair programming and code generation
###############################################################################
{
  config,
  pkgs,
  lib,
  profile,
  ...
}: let
  cfg = config.modules.dev.cursor-ide;
  mcpEnabled = config.modules.dev.mcp.enable;
  mcpConfig = {
    mcpServers = {
      "Brave Search" = {
        args = ["BRAVE_API_KEY=$BRAVE_API_KEY" "npx" "-y" "@modelcontextprotocol/server-brave-search"];
        command = "env";
      };
      "Filesystem" = {
        args = ["-y" "@modelcontextprotocol/server-filesystem" "~"];
        command = "npx";
      };
      "Stock Trader" = {
        args = ["TIINGO_API_KEY=$TIINGO_API_KEY" "mcp-trader"];
        command = "uvx";
      };
      "Nixos MCP" = {
        args = ["mcp-nixos"];
        command = "uvx";
      };
    };
  };

  # Generate MCP config file
  mcpConfigFile = pkgs.writeText "cursor-mcp.json" (builtins.toJSON mcpConfig);
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.dev.cursor-ide = {
    enable = lib.mkEnableOption "Cursor IDE";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      code-cursor
    ];

    ###########################################################################
    # MCP Configuration
    ###########################################################################
    home.file.".cursor/mcp.json" = lib.mkIf mcpEnabled {
      source = mcpConfigFile;
    };
  };
}
