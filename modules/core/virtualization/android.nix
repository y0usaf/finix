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

  config = lib.mkIf config.services.waydroid.enable {
    virtualisation.waydroid.enable = true;
    boot.kernelModules = [
      "ashmem_linux"
      "binder_linux"
    ];
  };
}
