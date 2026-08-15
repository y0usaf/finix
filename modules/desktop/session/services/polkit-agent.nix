{
  config,
  lib,
  pkgs,
  ...
}: {
  options.user.services.polkitAgent = {
    enable = lib.mkEnableOption "polkit authentication agent";
  };
  config = lib.mkIf config.user.services.polkitAgent.enable {
    environment.systemPackages = [pkgs.polkit_gnome];
  };
}
