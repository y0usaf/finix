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
        args = ["BRAVE_API_KEY=BSAFZkv_tdb_2PaF_kverNMM9Y5sXk8" "npx" "-y" "@modelcontextprotocol/server-brave-search"];
        command = "env";
      };
      "Filesystem" = {
        args = ["-y" "@modelcontextprotocol/server-filesystem" "~"];
        command = "npx";
      };
      "Nixos MCP" = {
        args = ["--install-deps" "mcp-nixos"];
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
