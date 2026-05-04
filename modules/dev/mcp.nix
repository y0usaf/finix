{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) toJSON;
  mcpServers = lib.listToAttrs (map
    (spec:
      lib.nameValuePair spec.name {
        type = "stdio";
        inherit (spec) command args;
        env = spec.environment;
      })
    (import ./servers.nix {inherit config;}));
  inherit (config) user;
in {
  options.user.dev.mcp = {
    enable = lib.mkEnableOption "Model Context Protocol configuration";
  };
  config = lib.mkIf user.dev.mcp.enable {
    environment.systemPackages = [
      pkgs.bun
      pkgs.uv
    ];
    manzil.users."${config.user.name}" = {
      files = let
        mcpConfig = toJSON {inherit mcpServers;};
      in {
        ".cursor/mcp.json" = {
          text = mcpConfig;
        };
        ".claude/mcp_config.json" = {
          text = mcpConfig;
        };
        ".claude/mcp_servers.json" = {
          text = toJSON mcpServers;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${user.homeDirectory}/.local/share/bun 0755 ${user.name} users - -"
    ];
  };
}
