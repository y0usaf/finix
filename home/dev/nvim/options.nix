###############################################################################
# Neovim Module Options
###############################################################################
{lib, ...}: {
  options.home.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced Neovim with MNW wrapper";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };
}