{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.prime-agent = {
    enable = lib.mkEnableOption "Prime Agent coding agent";
  };

  config = lib.mkIf config.user.dev.prime-agent.enable {
    environment.systemPackages = [
      flakeInputs.prime-agent-flake.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
