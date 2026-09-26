{lib, ...}: {
  services = {
    dhcpcd.enable = lib.mkForce false;
    networkmanager = {
      enable = true;
      settings.main.rc-manager = "resolvconf";
    };
  };
  finit.services.dhcpcd.enable = lib.mkForce false;
  programs.resolvconf.enable = true;
}
