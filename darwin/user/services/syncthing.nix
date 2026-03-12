{config, ...}: {
  home-manager.users."${config.user.name}".services.syncthing = {
    enable = true;

    settings = {
      devices = import ../../../lib/syncthing.nix;

      folders = {
        tokens = {
          id = "bv79n-fh4kx";
          label = "Tokens";
          path = "${config.user.homeDirectory}/Tokens";
          devices = ["desktop" "laptop" "server" "phone"];
        };
      };
    };
  };
}
