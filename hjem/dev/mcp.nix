###############################################################################
# Model Context Protocol (MCP) Hjem Module
# Configures MCP servers using Hjem's file management system
# - Creates the .cursor/mcp.json configuration file
# - Installs required packages (nodejs, uv)
# - Sets up environment variables
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.cfg.hjome.dev.mcp;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.hjome.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration via Hjem";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Packages
    ###########################################################################
    packages = with pkgs; [
      nodejs_20
      uv
    ];

    ###########################################################################
    # Environment Variables
    ###########################################################################
    environment.sessionVariables = {
      NODE_PATH = "${config.xdg.dataDirectory}/npm/lib/node_modules";
    };

    ###########################################################################
    # MCP Configuration File
    ###########################################################################
    files.".cursor/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = {
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
          "GitHub Repo MCP" = {
            command = "npx";
            args = ["-y" "github-repo-mcp"];
          };
        };
      };
    };
  };
}
