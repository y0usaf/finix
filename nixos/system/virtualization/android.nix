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

  config = {
    virtualisation.waydroid = lib.mkIf config.services.waydroid.enable {
      enable = true;
    };
  };
}
