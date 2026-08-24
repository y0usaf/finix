_: {
  services = {
    mdevd.enable = true;
    sysklogd.enable = true;
    dhcpcd.enable = true;
    openssh.enable = true;
  };

  programs = {
    bash.enable = true;
    sudo.enable = true;
  };
}
