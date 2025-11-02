{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ''
        -- Telescope setup
        require("telescope").setup({})
        pcall(require("telescope").load_extension, "fzf")

        -- Treesitter setup
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
          indent = { enable = true },
        })

        -- UI plugins
        require("lualine").setup({ options = { theme = "cyberdream", globalstatus = true } })
        require("gitsigns").setup({ current_line_blame = true })
        require("ibl").setup({})
        require("dropbar").setup({})
        require("dressing").setup({})
        require("windows").setup({})
      '';
    };
  };
}
