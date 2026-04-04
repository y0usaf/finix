{lib, ...}: {
  options.user.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced Neovim with MNW wrapper";
  };
}
