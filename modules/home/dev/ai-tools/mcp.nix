{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.mcp;
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
  options.home.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };
  config = lib.mkIf cfg.enable {
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        nodejs_20
        uv
      ];
      file.home = {
        ".cursor/mcp.json".text = builtins.toJSON mcpServersConfig;
        ".claude/mcp_config.json".text = builtins.toJSON mcpServersConfig;
        ".claude/mcp_servers.json".text = builtins.toJSON claudeCodeServers;
      };
    };
    users.users.y0usaf.maid.systemd.tmpfiles.dynamicRules = [
      "d {{home}}/.local/share/npm/lib/node_modules 0755 {{user}} {{group}} - -"
    ];
    system.activationScripts.setupClaudeMcp = {
      text = ''
        echo "Setting up Claude MCP servers via CLI..."
        add_mcp_server() {
          local name="$1"
          local command="$2"
          shift 2
          local args="$@"
          if ! runuser -u y0usaf -- ${pkgs.claude-code}/bin/claude mcp list | grep -q "$name"; then
            echo "Adding MCP server: $name"
            runuser -u y0usaf -- ${pkgs.claude-code}/bin/claude mcp add --scope user "$name" "$command" $args
          else
            echo "MCP server already exists: $name"
          fi
        }
        add_mcp_server "Filesystem" "npx" "@modelcontextprotocol/server-filesystem" "/home/y0usaf"
        add_mcp_server "sequential-thinking" "npx" "@modelcontextprotocol/server-sequential-thinking"
        add_mcp_server "GitHub Repo MCP" "npx" "github-repo-mcp"
        add_mcp_server "Gemini MCP" "npx" "gemini-mcp-tool"
        echo "Claude MCP servers setup complete"
      '';
      deps = [];
    };
  };
}
