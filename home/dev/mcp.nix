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

  # Claude Code specific format (just the servers, no wrapper)
  claudeCodeServers = {
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
        ".claude/mcp_servers.json".text = builtins.toJSON claudeCodeServers;
      };
    };

    ###########################################################################
    # Environment Variables (via systemd)
    ###########################################################################
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
    ];

    ###########################################################################
    # System Activation Script - Use Claude CLI to add MCP servers
    ###########################################################################
    system.activationScripts.setupClaudeMcp = {
      text = ''
        echo "Setting up Claude MCP servers via CLI..."
        
        # Function to add MCP server if not already present
        add_mcp_server() {
          local name="$1"
          local type="$2"
          local command="$3"
          shift 3
          local args="$@"
          
          # Check if server already exists
          if ! runuser -u y0usaf -- ${pkgs.claude-code}/bin/claude mcp list | grep -q "$name"; then
            echo "Adding MCP server: $name"
            runuser -u y0usaf -- ${pkgs.claude-code}/bin/claude mcp add "$name" "$type" "$command" $args
          else
            echo "MCP server already exists: $name"
          fi
        }
        
        # Add all MCP servers
        add_mcp_server "Filesystem" "stdio" "npx" "-y" "@modelcontextprotocol/server-filesystem" "/home/y0usaf"
        add_mcp_server "Nixos MCP" "stdio" "uvx" "mcp-nixos"
        add_mcp_server "sequential-thinking" "stdio" "npx" "-y" "@modelcontextprotocol/server-sequential-thinking"
        add_mcp_server "GitHub Repo MCP" "stdio" "npx" "-y" "github-repo-mcp"
        add_mcp_server "Gemini MCP" "stdio" "npx" "-y" "gemini-mcp-tool"
        
        echo "Claude MCP servers setup complete"
      '';
      deps = [];
    };
  };
}
