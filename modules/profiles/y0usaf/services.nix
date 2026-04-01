{
  config,
  lib,
  ...
}: {
  user.services = {
    ssh.enable = true;
    polkitAgent.enable = true;
    formatNix.enable = true;
    udiskie.enable = true;
    syncthing = {
      enable = true;

      folders =
        {
          tokens = {
            id = "bv79n-fh4kx";
            label = "Tokens";
            path = "~/Tokens";
            devices = ["desktop" "laptop" "framework" "server" "phone"];
          };
        }
        // lib.optionalAttrs (config.networking.hostName == "y0usaf-desktop") {
          music = {
            id = "oty33-aq3dt";
            label = "Music";
            path = "~/Music";
            devices = ["desktop" "server" "phone"];
          };
          dcim = {
            id = "ti9yk-zu3xs";
            label = "DCIM";
            path = "~/DCIM";
            devices = ["desktop" "server" "phone"];
          };
          pictures = {
            id = "zbxzv-35v4e";
            label = "Pictures";
            path = "~/Pictures";
            devices = ["desktop" "server" "phone"];
          };
        };
    };
  };
}
