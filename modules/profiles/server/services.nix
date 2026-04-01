_: {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
    };
  };

  user.services = {
    formatNix.enable = true;
    ssh.enable = true;
    syncthing = {
      enable = true;

      folders = {
        tokens = {
          id = "bv79n-fh4kx";
          label = "Tokens";
          path = "~/Tokens";
          devices = ["desktop" "laptop" "server" "phone"];
          type = "receiveonly";
        };
        music = {
          id = "oty33-aq3dt";
          label = "Music";
          path = "~/Music";
          devices = ["desktop" "server" "phone"];
          type = "receiveonly";
        };
        dcim = {
          id = "ti9yk-zu3xs";
          label = "DCIM";
          path = "~/DCIM";
          devices = ["desktop" "server" "phone"];
          type = "receiveonly";
        };
        pictures = {
          id = "zbxzv-35v4e";
          label = "Pictures";
          path = "~/Pictures";
          devices = ["desktop" "server" "phone"];
          type = "receiveonly";
        };
      };
    };
  };
}
