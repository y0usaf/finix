# Laptop power/session stack. Elogind owns login runtime directories and lid
# policy; zzz remains available for explicit suspend and provider hooks.
{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    elogind.enable = true;
    power-profiles-daemon = {
      enable = true;
      extraGroups = [config.services.seatd.group];
    };
    fwupd.enable = true;
  };
  programs = {
    brightnessctl.enable = true;
    zzz.enable = true;
  };

  environment = {
    etc."elogind/logind.conf".text = lib.mkForce ''
      [Login]
      HandlePowerKey=poweroff
      HandleLidSwitch=suspend
      HandleLidSwitchExternalPower=suspend
      HandleLidSwitchDocked=ignore
      LidSwitchIgnoreInhibited=no
    '';
    systemPackages = [pkgs.acpi];
  };
}
