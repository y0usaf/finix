{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.services.tailscale.enableVPN {
    networking.hosts = {
      "100.105.204.116" = ["forgejo" "forge"];
    };
  };
}
