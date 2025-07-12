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

        {
          "Bekaboo/dropbar.nvim",
          event = "UIEnter",
          opts = {
            bar = {
              padding = {
                left = 1,
                right = 1,
              },
            },
            menu = {
              preview = false,
            },
            sources = {
              path = {
                relative_to = function()
                  return vim.fn.getcwd()
                end,
              },
            },
          },
        },
        { "stevearc/dressing.nvim", event = "VeryLazy", opts = {} },

        {
          "anuvyklack/windows.nvim",
          event = "UIEnter",
          dependencies = {
            "anuvyklack/middleclass",
          },
          opts = {
            autowidth = {
              enable = true,
              winwidth = 5,
              filetype = {
                help = 2,
              },
            },
            ignore = {
              buftype = { "quickfix" },
              filetype = { "NvimTree", "neo-tree", "undotree", "gundo" },
            },
          },
          config = function(_, opts)
            require("windows").setup(opts)
          end,
        },

        {
          "nvim-neo-tree/neo-tree.nvim",
          cmd = "Neotree",
          dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
          },
          opts = {
            filesystem = {
              follow_current_file = { enabled = true },
              hijack_netrw_behavior = "open_current",
            },
            window = { width = 35 },
          },
        },

        {
          "nvim-lualine/lualine.nvim",
          event = "VeryLazy",
          opts = {
            options = {
              theme = "cyberdream",
              globalstatus = true,
              component_separators = { left = ""; right = ""; },
              section_separators = { left = ""; right = ""; },
            },
            sections = {
              lualine_a = { { "mode", fmt = function(str) return str:sub(1,1) end } },
              lualine_b = { "branch", "diff" },
              lualine_c = { { "filename", path = 1 } },
              lualine_x = { "diagnostics", "encoding", "filetype" },
              lualine_y = { "progress" },
              lualine_z = { "location" },
            },
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
            indent = {
              char = "▏",
              tab_char = "▏",
            },
            scope = {
              enabled = true,
              char = "─",
              show_start = true,
              show_end = true,
            },
          },
        },

        {
          "folke/flash.nvim",
          event = "VeryLazy",
          opts = {},
          keys = {
            { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
            { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
            { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
            { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
            { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
          },
        },

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
          opts = {
            direction = "float",
            float_opts = {
              border = "curved",
              winblend = 3,
            },
            size = function(term)
              if term.direction == "horizontal" then
                return 15
              elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
              end
            end,
          },
        },
      }
    '';
  };
}
