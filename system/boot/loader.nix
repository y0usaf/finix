###############################################################################
# Boot Loader Configuration
# Specific settings for boot loader and EFI:
# - Boot loader settings
# - EFI configuration
###############################################################################
_: {
  config = {
    boot.loader = {
      systemd-boot = {
        enable = true; # Use systemd-boot as the boot loader.
        configurationLimit = 20; # Retain up to 20 boot configurations.
      };
      efi = {
        canTouchEfiVariables = true; # Allow modifying EFI variables.
        efiSysMountPoint = "/boot"; # Mount point for the EFI partition.
      };
    };
  };
}
