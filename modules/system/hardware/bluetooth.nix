{
  lib,
  pkgs,
  hostConfig,
  ...
}: {
  config = {
    hardware.bluetooth = lib.mkIf (lib.attrByPath ["hardware" "bluetooth" "enable"] false hostConfig) {
      enable = true;
      powerOnBoot = true;
      settings =
        lib.attrByPath ["hardware" "bluetooth" "settings"] null
        hostConfig
        or {
          General = {
            ControllerMode = "dual";
            FastConnectable = true;
          };
        };
      package = pkgs.bluez;
    };
    services.dbus.packages = lib.mkIf (lib.attrByPath ["hardware" "bluetooth" "enable"] false hostConfig) [pkgs.bluez];
    environment.systemPackages = lib.optionals (lib.attrByPath ["hardware" "bluetooth" "enable"] false hostConfig) [
      pkgs.bluez
      pkgs.bluez-tools
    ];
  };
}
