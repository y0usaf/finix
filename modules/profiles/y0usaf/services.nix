{...}: {
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
          versioning.type = "trashcan";
        };
        music = {
          id = "oty33-aq3dt";
          label = "Music";
          path = "~/Music";
          devices = ["desktop" "laptop" "framework" "server" "phone"];
          versioning.type = "trashcan";
        };
        dcim = {
          id = "ti9yk-zu3xs";
          label = "DCIM";
          path = "~/DCIM";
          devices = ["desktop" "laptop" "framework" "server" "phone"];
          versioning.type = "trashcan";
        };
        pictures = {
          id = "zbxzv-35v4e";
          label = "Pictures";
          path = "~/Pictures";
          devices = ["desktop" "laptop" "framework" "server" "phone"];
          versioning.type = "trashcan";
        };
      };
    };
  };
}
