_: {
  config = {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        25565
      ];
      allowedUDPPorts = [
      ];
    };
  };
}
