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
    # Configuration
    ###########################################################################
    home = {
      ###########################################################################
      # Packages
      ###########################################################################
      packages = with pkgs; [
        nodejs_20
        uv
      ];

      ###########################################################################
      # MCP Configuration (JSON file)
      ###########################################################################
      file.".cursor/mcp.json" = {
        text = builtins.toJSON {
          mcpServers = {
            "Brave Search" = {
              command = "npx";
              args = ["-y" "@modelcontextprotocol/server-brave-search"];
              env = {BRAVE_API_KEY = cfg.braveApiKey;};
            };
            "Filesystem" = {
              command = "npx";
              args = ["-y" "@modelcontextprotocol/server-filesystem" "~"];
            };
            "Nixos MCP" = {
              command = "uvx";
              args = ["mcp-nixos"];
            };
            "sequential-thinking" = {
              command = "npx";
              args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
            };
            "Memory" = {
              command = "npx";
              args = ["-y" "@modelcontextprotocol/server-memory"];
            };
            "hjem Docs" = {
              url = "https://gitmcp.io/feel-co/hjem/";
            };
            "nix Docs" = {
              url = "https://gitmcp.io/NixOS/nix";
            };
          };
        };
      };

      ###########################################################################
      # Environment Setup
      ###########################################################################
      sessionPath = [
        "${config.xdg.dataHome}/npm/bin"
      ];

      sessionVariables = {
        BRAVE_API_KEY = cfg.braveApiKey;
      };
    };
  };
}
