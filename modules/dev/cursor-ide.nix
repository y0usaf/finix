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
        command = "env";
        args = ["sh" "-c" "BRAVE_API_KEY=$(cat ~/Tokens/BRAVE_API_KEY.txt) npx -y @modelcontextprotocol/server-brave-search"];
      };
      "Filesystem" = {
        args = ["-y" "@modelcontextprotocol/server-filesystem" "~"];
        command = "npx";
      };
      "Stock Trader" = {
        command = "env";
        args = ["sh" "-c" "TIINGO_API_KEY=$(cat ~/Tokens/TIINGO_API_KEY.txt) uvx mcp-trader"];
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
