_: {
  services = {
    bluetooth.enable = true;
    polkit.enable = true;
    rtkit.enable = true;
    upower.enable = true;
    udisks2.enable = true;
    nftables.enable = true;
  };

  hardware.i2c.enable = true;

  xdg = {
    portal.enable = true;
    icons.enable = true;
    mime.enable = true;
  };

  fonts.fontconfig.enable = true;
}
