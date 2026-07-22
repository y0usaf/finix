_: {
  services.openssh = {
    enable = true;
    # 2222 is taken by forgejo's ssh listener on this host.
    ports = [2200];
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
