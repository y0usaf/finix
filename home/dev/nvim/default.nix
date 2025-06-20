###############################################################################
# Enhanced Neovim Configuration with MNW + nix-maid
# Modular configuration for modern Neovim development environment
###############################################################################
{...}: {
  imports = [
    ./options.nix
    ./config.nix
    ./neovide.nix
  ];
}
