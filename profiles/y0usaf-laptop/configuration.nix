#===============================================================================
#                          💻 NixOS Laptop Configuration 💻
#===============================================================================
# This file imports the shared desktop configuration and laptop-specific hardware
# configuration, allowing for consistent settings across devices while maintaining
# hardware-specific configurations.
#
# ⚠️  Root access required | System rebuild needed for changes
#===============================================================================
{...}: {
  imports = [
    ../configurations/default.nix
    ./hardware-configuration.nix
    ../../modules/btrfs-schema.nix
  ];

  # Enable and configure the BTRFS schema
  btrfsSchema = {
    enable = true;
    createSubvolumes = true;  # Set to true for initial setup
    rootDevice = "f3d25172-f728-4bb6-a14d-f86e97a6a0e7";  # Your root UUID
    bootDevice = "5330-BB8D";  # Your boot UUID
    # mediaDevice is optional now - will use rootDevice if not specified
  };
}
