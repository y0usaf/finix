{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.tailscale.enableVPN {
    networking.hosts = {
      "100.90.54.18" = ["syncthing-desktop"];
      "100.105.204.116" = ["forgejo" "syncthing-server"];
    };
  };
}
