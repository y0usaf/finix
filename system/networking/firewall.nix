###############################################################################
# Firewall Configuration
# Network security settings:
# - Firewall rules and port management
###############################################################################
_: {
  config = {
    ###########################################################################
    # Firewall Configuration
    # Network security and port management
    ###########################################################################
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        25565  # Minecraft server
      ];
      allowedUDPPorts = [
        # Add UDP ports if needed
      ];
    };
  };
}