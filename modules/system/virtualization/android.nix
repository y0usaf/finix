{
  lib,
  hostSystem,
  ...
}: {
  config = {
    virtualisation.waydroid = lib.mkIf (hostSystem.services.waydroid.enable or false) {
      enable = true;
    };
  };
}
