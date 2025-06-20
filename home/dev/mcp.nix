###############################################################################
# Model Context Protocol (MCP) Development Module (Maid Version)
# Configures MCP servers using nix-maid file management system
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
  cfg = config.home.dev.mcp;
  
  # Shared MCP servers configuration
  mcpServersConfig = {
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
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        nodejs_20
        uv
      ];

      ###########################################################################
      # MCP Configuration Files
      ###########################################################################
      file.home = {
        ".cursor/mcp.json".text = builtins.toJSON mcpServersConfig;
        ".claude/mcp_config.json".text = builtins.toJSON mcpServersConfig;
      };
    };

    ###########################################################################
    # Environment Variables (via systemd)
    ###########################################################################
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
    ];
  };
}
