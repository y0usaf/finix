###############################################################################
# Hardware Configuration Modules
# Centralized hardware-specific configurations:
# - Input devices (keyboards, controllers)
# - Video devices (cameras, capture)
###############################################################################
{
  imports = [
    ./input.nix
    ./video.nix
  ];
}