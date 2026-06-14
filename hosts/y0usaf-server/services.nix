_: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  user.services = {
    ssh.enable = true;
    formatNix.enable = true;
    syncthing.enable = true;
  };
}
