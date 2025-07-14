{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/lua/plugins_appearance.lua".text = ''
      return {
        -- Theme
        {
          "scottmckendry/cyberdream.nvim",
          lazy = false,
          priority = 1000,
          config = function()
            require("cyberdream").setup({
              transparent = true,
              italic_comments = true,
              borderless_pickers = true,
              lualine_style = "default",
              theme = {
                variant = "default",
                highlights = {
                  CursorLine = { bg = "#1e1e2e" },
                  Visual = { bg = "#313244" },
                  Search = { bg = "#f9e2af", fg = "#11111b" },
                  IncSearch = { bg = "#fab387", fg = "#11111b" },
                },
              },
            })
            vim.cmd.colorscheme("cyberdream")
          end,
        },

        -- UI Components
        {
          "Bekaboo/dropbar.nvim",
          event = "UIEnter",
          opts = { menu = { preview = false } },
        },
        { "stevearc/dressing.nvim", event = "VeryLazy", opts = {} },
        {
          "anuvyklack/windows.nvim",
          event = "UIEnter",
          dependencies = { "anuvyklack/middleclass" },
          opts = {
            autowidth = { enable = true, winwidth = 5, filetype = { help = 2 } },
            ignore = {
              buftype = { "quickfix" },
              filetype = { "NvimTree", "neo-tree", "undotree", "gundo" },
            },
          },
        },
        {
          "nvim-neo-tree/neo-tree.nvim",
          cmd = "Neotree",
          dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
          opts = {
            filesystem = { follow_current_file = { enabled = true }, hijack_netrw_behavior = "open_current" },
            window = { width = 35 },
          },
        },
        {
          "nvim-lualine/lualine.nvim",
          event = "VeryLazy",
          opts = {
            options = { theme = "cyberdream", globalstatus = true },
          },
        },
        {
          "lewis6991/gitsigns.nvim",
          event = { "BufReadPre", "BufNewFile" },
          opts = {
            signs = {
              add = { text = "┃" },
              change = { text = "┃" },
              delete = { text = " " },
              topdelete = { text = "▔" },
              changedelete = { text = "~" },
              untracked = { text = "┆" },
            },
            current_line_blame = true,
          },
        },
        {
          "lukas-reineke/indent-blankline.nvim",
          main = "ibl",
          opts = {
            indent = { char = "▏", tab_char = "▏" },
            scope = { enabled = true, char = "─", show_start = true, show_end = true },
          },
        },
        { "folke/flash.nvim", event = "VeryLazy", opts = {} },
        {
          "echasnovski/mini.hipatterns",
          event = "VeryLazy",
          opts = function()
            local hipatterns = require("mini.hipatterns")
            return {
              highlighters = {
                fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
                hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
                todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
                note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
                hex_color = hipatterns.gen_highlighter.hex_color(),
              },
            }
          end,
        },
        {
          "akinsho/toggleterm.nvim",
          keys = { "<C-\\>" },
          opts = { direction = "float", float_opts = { border = "curved" } },
        },
      }
    '';
  };
}
