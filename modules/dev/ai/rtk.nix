{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.user) dev;
in {
  options.user.dev.rtk = {
    enable = lib.mkEnableOption "rtk binary";
  };

  config = lib.mkIf dev.rtk.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".local/share/rtk"
    ];
    environment.systemPackages = [
      pkgs.rtk
    ];
  };
}
