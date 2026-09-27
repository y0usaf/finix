{lib, ...}: {
  options.user.dev.pi = {
    enable = lib.mkEnableOption "pi coding agent CLI";

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
