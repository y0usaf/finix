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
        args = ["-y" "@modelcontextprotocol/server-filesystem" config.user.homeDirectory];
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
      args = ["-y" "@modelcontextprotocol/server-filesystem" config.user.homeDirectory];
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
    hjem.users.${config.user.name} = {
      packages = with pkgs; [
        nodejs_20
        uv
      ];
      files = {
        ".cursor/mcp.json" = {
          text = builtins.toJSON mcpServersConfig;
          clobber = true;
        };
        ".claude/mcp_config.json" = {
          text = builtins.toJSON mcpServersConfig;
          clobber = true;
        };
        ".claude/mcp_servers.json" = {
          text = builtins.toJSON claudeCodeServers;
          clobber = true;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/npm/lib/node_modules 0755 ${config.user.name} users - -"
    ];
    # system.activationScripts.setupClaudeMcp = {
    #   text = ''
    #     echo "Setting up Claude MCP servers via CLI..."
    #     add_mcp_server() {
    #       local name="$1"
    #       local command="$2"
    #       shift 2
    #       local args="$@"
    #       if ! runuser -u ${config.user.name} -- ${pkgs.claude-code}/bin/claude mcp list | grep -q "$name"; then
    #         echo "Adding MCP server: $name"
    #         runuser -u ${config.user.name} -- ${pkgs.claude-code}/bin/claude mcp add --scope user "$name" "$command" $args
    #       else
    #         echo "MCP server already exists: $name"
    #       fi
    #     }
    #     add_mcp_server "Filesystem" "npx" "@modelcontextprotocol/server-filesystem" "${config.user.homeDirectory}"
    #     add_mcp_server "sequential-thinking" "npx" "@modelcontextprotocol/server-sequential-thinking"
    #     add_mcp_server "GitHub Repo MCP" "npx" "github-repo-mcp"
    #     add_mcp_server "Gemini MCP" "npx" "gemini-mcp-tool"
    #     echo "Claude MCP servers setup complete"
    #   '';
    #   deps = [];
    # };
  };
}
