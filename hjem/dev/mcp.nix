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
      NODE_PATH = "${config.xdg.dataHome or "~/.local/share"}/npm/lib/node_modules";
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
  };
}