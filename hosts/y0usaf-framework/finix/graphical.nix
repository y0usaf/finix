# Framework AMD graphics + eudev/seat stack. No desktop NVIDIA settings leak
# into this host; CPU speculation mitigations remain enabled.
{
  config,
  lib,
  ...
}: {
  hardware = {
    nvidia.enable = false;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services = {
    mdevd.enable = lib.mkForce false;
    udev.enable = true;
    seatd.enable = true;
    dbus.enable = true;
  };

  users.users.${config.user.name}.extraGroups = ["video" "render" "seat"];
}
