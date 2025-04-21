###############################################################################
# Model Context Protocol (MCP) Module
# Installs and configures the Model Context Protocol servers:
# - Brave Search server via npm
# - Filesystem server via npm
# - Adds npm bin directory to PATH
# - Provides configuration options for the MCP servers
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.dev.mcp;

  # Create a script that generates the MCP config
  generateMcpConfig = pkgs.writeShellScript "generate-mcp-config" ''
    cat > ~/.cursor/mcp.json << EOF
    {
      "mcpServers": {
        "Brave Search": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-brave-search"],
          "env": {
            "BRAVE_API_KEY": "$BRAVE_API_KEY"
          }
        },
        "Filesystem": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-filesystem", "~"]
        },
        "Nixos MCP": {
          "command": "uvx",
          "args": ["mcp-nixos"]
        },
        "sequential-thinking": {
          "command": "npx",
          "args": [
            "-y",
            "@modelcontextprotocol/server-sequential-thinking"
          ]
        },

      }
    }
    EOF
  '';
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol servers";
    braveApiKey = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Brave Search API key for MCP";
    };
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    home.packages = with pkgs; [
      nodejs_20
      uv

    ];

    ###########################################################################
    # MCP Configuration
    ###########################################################################
    home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ~/.cursor
      $DRY_RUN_CMD ${generateMcpConfig}
    '';

    ###########################################################################
    # Environment Setup
    ###########################################################################
    home.sessionPath = [
      "${config.xdg.dataHome}/npm/bin"
    ];

    home.sessionVariables = {
      BRAVE_API_KEY = cfg.braveApiKey;
    };
  };
}
