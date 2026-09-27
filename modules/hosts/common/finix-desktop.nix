{
  config,
  lib,
  pkgs,
  ...
}: {
  services = {
    bluetooth.enable = true;
    polkit.enable = true;
    rtkit.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    nftables.enable = true;
    dhcpcd.enable = lib.mkForce false;
    networkmanager = {
      enable = true;
      settings.main.rc-manager = "resolvconf";
    };
  };

  finit.services.dhcpcd.enable = lib.mkForce false;
  users.users.${config.user.name}.extraGroups = ["networkmanager"];

  system.activation.scripts.networkManagerConnections = {
    deps = ["etc"];
    text = ''
      src=/persist/etc/NetworkManager/system-connections
      dst=/etc/NetworkManager/system-connections
      ${pkgs.coreutils}/bin/install -d -m 0700 "$dst"
      if [ -d "$src" ]; then
        ${pkgs.findutils}/bin/find "$src" -maxdepth 1 -type f -exec \
          ${pkgs.coreutils}/bin/install -m 0600 -o root -g root {} "$dst/" \;
      fi
    '';
  };
  programs.resolvconf.enable = true;

  hardware.i2c.enable = true;

  xdg = {
    portal.enable = true;
    icons.enable = true;
    mime.enable = true;
  };

  fonts.fontconfig.enable = true;
}
