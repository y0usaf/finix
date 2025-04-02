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

  # Get environment variables at build time
  braveApiKey = builtins.getEnv "BRAVE_API_KEY";
  tiingoApiKey = builtins.getEnv "TIINGO_API_KEY";

  # Create JSON content directly as a string
  mcpConfigJson = ''
    {
      "mcpServers": {
        "Brave Search": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-brave-search"],
          "env": {
            "BRAVE_API_KEY": "${braveApiKey}"
          }
        },
        "Filesystem": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-filesystem", "~"]
        },
        "Stock Trader": {
          "command": "uvx",
          "args": ["mcp-trader"],
          "env": {
            "TIINGO_API_KEY": "${tiingoApiKey}"
          }
        },
        "Nixos MCP": {
          "command": "uvx",
          "args": ["mcp-nixos"]
        }
      }
    }
  '';
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
      text = mcpConfigJson;
    };
  };
}
