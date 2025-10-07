_: {
  config = {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        3000 # Forgejo
        22000 # Syncthing
        25565 # Minecraft
      ];
      allowedUDPPorts = [
        22000 # Syncthing
        21027 # Syncthing discovery
      ];
    };
  };
}
