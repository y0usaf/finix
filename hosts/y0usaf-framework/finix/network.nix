# Framework is Wi-Fi-first. Reuse persisted NetworkManager profiles; never run
# dhcpcd beside NetworkManager against the same interface.
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
