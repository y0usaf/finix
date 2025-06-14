###############################################################################
# Home Modules Collection (Maid)
# Imports all home-related modules for nix-maid integration
###############################################################################
{helpers, ...}: {
  imports = [
    ./core
    ./dev
    ./gaming
    ./programs
    ./shell
    ./tools
    ./ui
  ];
}