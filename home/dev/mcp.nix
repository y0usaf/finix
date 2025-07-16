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
        type = "stdio";
        command = "npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" "/home/y0usaf"];
        env = {};
      };
      "Nixos MCP" = {
        type = "stdio";
        command = "uvx";
        args = ["mcp-nixos"];
        env = {};
      };
      "sequential-thinking" = {
        type = "stdio";
        command = "npx";
        args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
        env = {};
      };
      "GitHub Repo MCP" = {
        type = "stdio";
        command = "npx";
        args = ["-y" "github-repo-mcp"];
        env = {};
      };
      "Gemini MCP" = {
        type = "stdio";
        command = "npx";
        args = ["-y" "gemini-mcp-tool"];
        env = {};
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
    # System Activation Script for writable .claude.json
    ###########################################################################
    system.activationScripts.write-claude-config = ''
      mkdir -p /home/y0usaf
      cat > /home/y0usaf/.claude.json << 'EOF'
      ${builtins.toJSON mcpServersConfig}
      EOF
      chown y0usaf:users /home/y0usaf/.claude.json 2>/dev/null || true
      chmod 644 /home/y0usaf/.claude.json
    '';
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
