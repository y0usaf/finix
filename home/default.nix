###############################################################################
# Home Modules Collection (Maid)
# Imports all home-related modules for nix-maid integration
###############################################################################
{helpers, ...}: {
  imports = [
    ./core
    ./gaming
    ./programs
    ./services
    ./shell
    ./tools
    ./ui
  ];
}