{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  options.user.dev.work.agent-slack = {
    enable = lib.mkEnableOption "agent-slack CLI";
  };

  config = lib.mkIf config.user.dev.work.agent-slack.enable {
    environment.systemPackages = [
      flakeInputs.agent-slack.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];
  };
}
