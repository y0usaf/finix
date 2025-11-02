{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ''
        -- Utility plugin configurations
        require("Comment").setup({})
        require("nvim-autopairs").setup({})
        require("ufo").setup({})
        require("fidget").setup({})
        require("illuminate").configure({})
        require("twilight").setup({})
        require("toggleterm").setup({ direction = "float" })
        require("flash").setup({})
        require("mini.hipatterns").setup({})
      '';
    };
  };
}
