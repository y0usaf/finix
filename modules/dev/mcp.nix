###############################################################################
# Model Context Protocol (MCP) Module
# Installs and configures the Model Context Protocol server for Brave Search
# - Installs MCP Brave Search server via npm
# - Adds npm bin directory to PATH
# - Provides configuration options for the MCP server
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.modules.dev.mcp;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.modules.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol for Brave Search";
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
    ];

    ###########################################################################
    # Installation
    ###########################################################################
    home.activation.installMCP = lib.hm.dag.entryAfter ["npmSetup"] ''
      # Install Model Context Protocol servers globally via npm
      ${pkgs.nodejs_20}/bin/npm install -g @modelcontextprotocol/server-brave-search
      ${pkgs.nodejs_20}/bin/npm install -g @modelcontextprotocol/server-filesystem
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
