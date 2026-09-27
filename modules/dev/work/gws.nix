{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.dev.work.gws.enable = lib.mkEnableOption "Google Workspace CLI";

  config = lib.mkIf config.user.dev.work.gws.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".config/gws"
      ".config/gws-inscend"
    ];
    environment.systemPackages = [pkgs.gws];
  };
}
