{
  config,
  pkgs,
  lib,
  ...
}: {
  options.user.programs.slack = {
    enable = lib.mkEnableOption "Slack package";
  };

  config = lib.mkIf config.user.programs.slack.enable {
    environment.systemPackages = [pkgs.slack];
  };
}
