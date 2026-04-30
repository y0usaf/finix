{
  config,
  lib,
  ...
}: let
  cfg = config.user.dev.pi;
  hiveCfg = cfg.hive;
  inherit (lib) types;
in {
  options.user.dev.pi.hive = {
    enable = lib.mkEnableOption "pi-hive extension";

    maxDepth = lib.mkOption {
      type = types.ints.unsigned;
      default = 1;
      description = "Maximum pi-hive child-agent recursion depth.";
    };

    maxLiveAgents = lib.mkOption {
      type = types.ints.positive;
      default = 20;
      description = "Maximum live pi-hive agents.";
    };

    workflows = lib.mkOption {
      type = with types; attrsOf lines;
      default = {};
      description = "Declarative pi-hive workflow prompt files, keyed by workflow name.";
    };
  };

  config = lib.mkIf (cfg.enable && hiveCfg.enable) {
    bayt.users."${config.user.name}".files =
      {
        ".pi/agent/pi-hive.json".text = builtins.toJSON {
          inherit (hiveCfg) maxDepth maxLiveAgents;
        };
      }
      // (lib.mapAttrs' (name: text:
        lib.nameValuePair ".pi/hive/workflows/${name}.md" {inherit text;})
      hiveCfg.workflows);
  };
}
