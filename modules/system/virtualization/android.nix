{
  lib,
  hostConfig,
  ...
}: {
  config = {
    virtualisation.waydroid = lib.mkIf (hostConfig.services.waydroid.enable or false) {
      enable = true;
    };
  };
}
