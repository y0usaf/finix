{
  config,
  lib,
  pkgs,
  ...
}: let
  mcpServerSpecs = import ./servers.nix {inherit config;};

  mkStdIOServer = spec: {
    type = "stdio";
    inherit (spec) command;
    inherit (spec) args;
    env = spec.environment;
  };

  mcpServersConfig = {
    mcpServers = lib.listToAttrs (map
      (spec: lib.nameValuePair spec.name (mkStdIOServer spec))
      mcpServerSpecs);
  };
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
          text = builtins.toJSON mcpServersConfig;
          clobber = true;
        };
        ".claude/mcp_config.json" = {
          text = builtins.toJSON mcpServersConfig;
          clobber = true;
        };
        ".claude/mcp_servers.json" = {
          text = builtins.toJSON (lib.listToAttrs (map
            (spec: lib.nameValuePair spec.name (mkStdIOServer spec))
            mcpServerSpecs));
          clobber = true;
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${config.user.homeDirectory}/.local/share/bun 0755 ${config.user.name} users - -"
    ];
  };
}
