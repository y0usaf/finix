{
  config,
  lib,
  ...
}: {
  options.services.waydroid = lib.mkOption {
    type = lib.types.submodule {
      options.enable = lib.mkEnableOption "Waydroid Android container";
    };
    default = {};
  };

  config.virtualisation.waydroid.enable = lib.mkIf config.services.waydroid.enable true;
}
