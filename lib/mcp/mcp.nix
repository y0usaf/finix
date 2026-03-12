{
  config,
  lib,
  pkgs,
  ...
}: let
  mcpServers = lib.listToAttrs (map
    (spec:
      lib.nameValuePair spec.name {
        type = "stdio";
        inherit (spec) command args;
        env = spec.environment;
      })
    (import ./servers.nix {inherit config;}));
in {
  options.user.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };
  config = lib.mkIf config.user.dev.mcp.enable {
    environment.systemPackages = [
      pkgs.bun
      pkgs.uv
    ];
    usr = {
      files = {
        ".cursor/mcp.json" = {
          text = builtins.toJSON {inherit mcpServers;};
          clobber = true;
        };
        ".claude/mcp_config.json" = {
          text = builtins.toJSON {inherit mcpServers;};
          clobber = true;
        };
        ".claude/mcp_servers.json" = {
          text = builtins.toJSON mcpServers;
          clobber = true;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/bun 0755 ${config.user.name} users - -"
    ];
  };
}
