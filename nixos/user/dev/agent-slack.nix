{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.agent-slack = {
    enable = lib.mkEnableOption "agent-slack CLI";
  };

  config = lib.mkIf config.user.dev.agent-slack.enable {
    environment.systemPackages = [
      flakeInputs.agent-slack.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
