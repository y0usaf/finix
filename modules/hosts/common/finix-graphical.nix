{
  config,
  lib,
  ...
}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services = {
    mdevd.enable = lib.mkForce false;
    udev.enable = true;
    seatd.enable = true;
    dbus.enable = true;
  };

  users.users.${config.user.name}.extraGroups = ["video" "render" "seat"];
}
