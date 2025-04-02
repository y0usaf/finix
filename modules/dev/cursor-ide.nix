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
        "Stock Trader": {
          "command": "uvx",
          "args": ["mcp-trader"],
          "env": {
            "TIINGO_API_KEY": "$TIINGO_API_KEY"
          }
        },
        "Nixos MCP": {
          "command": "uvx",
          "args": ["mcp-nixos"]
        }
      }
    }
    EOF
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
    home.activation.mcpConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ~/.cursor
      $DRY_RUN_CMD ${generateMcpConfig}
    '';
  };
}
