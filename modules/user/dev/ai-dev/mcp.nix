{
  config,
  lib,
  pkgs,
  ...
}: let
  mcpServerSpecs = import ./mcp-servers.nix {inherit config;};

  mkStdIOServer = spec: {
    type = "stdio";
    command = spec.command;
    args = spec.args;
    env = spec.environment;
  };

  mcpServersConfig = {
    mcpServers = lib.listToAttrs (map
      (spec: lib.nameValuePair spec.name (mkStdIOServer spec))
      mcpServerSpecs);
  };

  claudeCodeServers = lib.listToAttrs (map
    (spec: lib.nameValuePair spec.name (mkStdIOServer spec))
    mcpServerSpecs);
in {
  options.user.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };
  config = lib.mkIf config.user.dev.mcp.enable {
    environment.systemPackages = [
      pkgs.nodejs_20
      pkgs.uv
    ];
    usr = {
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
  };
}
