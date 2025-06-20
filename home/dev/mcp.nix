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
      # MCP Configuration File
      ###########################################################################
      file.home = {
        ".cursor/mcp.json".text = builtins.toJSON {
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

    ###########################################################################
    # Environment Variables (via systemd)
    ###########################################################################
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
    ];
  };
}
