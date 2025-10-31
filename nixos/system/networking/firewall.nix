_: {
  config = {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        3000
        22000
        25565
      ];
      allowedUDPPorts = [
        22000
        21027
      ];
    };
  };
}
