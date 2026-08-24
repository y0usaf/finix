{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.programs.webapps = {
    enable = lib.mkEnableOption "web applications via Chromium";
  };

  config = lib.mkIf config.user.programs.webapps.enable {
    environment.systemPackages = [pkgs.ungoogled-chromium];
  };
}
