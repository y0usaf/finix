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
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/chromium"
    ];
    environment.systemPackages = [pkgs.ungoogled-chromium];
  };
}
