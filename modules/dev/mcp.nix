{
  config,
  lib,
  pkgs,
  ...
}: let
  toJSON = lib.generators.toJSON {};
  inherit (config) user;
  mcpServers = lib.listToAttrs (map
    (spec:
      lib.nameValuePair spec.name {
        type = "stdio";
        inherit (spec) command args;
        env = spec.environment;
      })
    [
      {
        name = "Filesystem";
        command = "npx";
        args = ["-y" "@modelcontextprotocol/server-filesystem" user.homeDirectory];
        environment = {};
      }
      {
        name = "GitHub Repo MCP";
        command = "npx";
        args = ["-y" "github-repo-mcp"];
        environment = {};
      }
      {
        name = "Gemini MCP";
        command = "npx";
        args = ["-y" "gemini-mcp-tool"];
        environment = {};
      }
    ]);
in {
  options.user.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };
  config = lib.mkIf user.dev.mcp.enable {
    environment.systemPackages = [
      pkgs.bun
      pkgs.uv
    ];
    manzil.users."${config.user.name}".files = {
      ".cursor/mcp.json" = {
        generator = toJSON;
        value = {inherit mcpServers;};
      };
      ".claude/mcp_config.json" = {
        generator = toJSON;
        value = {inherit mcpServers;};
      };
      ".claude/mcp_servers.json" = {
        generator = toJSON;
        value = mcpServers;
      };
    };

    systemd.tmpfiles.rules = [
      "d ${user.homeDirectory}/.local/share/bun 0755 ${user.name} users - -"
    ];
  };
}
