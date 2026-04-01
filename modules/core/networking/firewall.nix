_: {
  config.networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      22000
    ];
    allowedUDPPorts = [
      22000
      21027
    ];
  };
}
