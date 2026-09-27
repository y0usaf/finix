{lib, ...}: let
  mkInternalStr = description:
    lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = "";
      inherit description;
    };
in {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";

    readmePath = mkInternalStr "Path to the pi README.";
    docsPath = mkInternalStr "Path to the pi docs directory.";
    examplesPath = mkInternalStr "Path to the pi examples directory.";

    agents = {
      maxDepth = lib.mkOption {
        type = lib.types.int;
        default = 1;
        description = ''
          Maximum descendant depth for pi-agents. Depth 0 disables spawning.
        '';
      };

      maxLiveAgents = lib.mkOption {
        type = lib.types.int;
        default = 6;
        description = ''
          Maximum number of live pi-agents children kept in memory.
        '';
      };
    };
  };
}
