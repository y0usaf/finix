###############################################################################
# Network Manager Configuration
# Network management service settings:
# - NetworkManager configuration
###############################################################################
_: {
  config = {
    ###########################################################################
    # Networking Configuration
    # Network management
    ###########################################################################
    networking.networkmanager.enable = true; # Turn on NetworkManager to manage network connections.
  };
}
