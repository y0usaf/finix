{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.agent-harness = {
    enable = lib.mkEnableOption "agent-harness";
  };

  config = lib.mkIf config.user.programs.agent-harness.enable {
    environment.systemPackages = [pkgs.agent-harness];
  };
}
