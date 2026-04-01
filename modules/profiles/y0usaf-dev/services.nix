_: {
  user.services = {
    ssh.enable = true;
    polkitAgent.enable = true;
    formatNix.enable = true;
    udiskie.enable = true;
    syncthing = {
      enable = true;

      folders = {
        tokens = {
          id = "bv79n-fh4kx";
          label = "Tokens";
          path = "~/Tokens";
          devices = ["desktop" "laptop" "framework" "server" "phone"];
        };
      };
    };
  };
}
