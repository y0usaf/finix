# Appearance settings for Neovim
{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file = {
      # Main appearance settings
      xdg_config."nvim/lua/appearance.lua".text = ''
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.signcolumn = "yes"
        vim.opt.wrap = true
        vim.opt.linebreak = true
        vim.opt.breakindent = true
        vim.opt.showbreak = "↪ "
        vim.opt.termguicolors = true
        vim.opt.scrolloff = 8
        vim.opt.sidescrolloff = 8
        vim.opt.cursorline = true
        vim.opt.cursorlineopt = "both"
        vim.opt.pumheight = 15
        vim.opt.pumblend = 0
        vim.opt.winblend = 0
        vim.opt.conceallevel = 2
        vim.opt.concealcursor = "niv"
        vim.opt.showmode = false
        vim.opt.laststatus = 2
        vim.opt.cmdheight = 1
        vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
        vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
      '';

      # Dashboard configuration
      xdg_config."nvim/lua/dashboard.lua".text = ''
        local dashboard = require("alpha.themes.dashboard")

        dashboard.section.header.val = {
          [[                               __                ]],
          [[  ____  _________  ____  ____/ /___  ____  _____]],
          [[ / __ \/ ___/ __ \/ __ \/ __  / __ \/ __ \/ ___/]],
          [[/ /_/ / /  / /_/ / /_/ / /_/ / /_/ / /_/ (__  ) ]],
          [[\____/_/   \____/ .___/\__,_/\____/\____/____/  ]],
          [[               /_/                             ]],
        }

        dashboard.section.buttons.val = {
          dashboard.button("e", "  New file", ":ene <BAR> startinsert <CR>"),
          dashboard.button("f", "  Find file", ":Telescope find_files<CR>"),
          dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
          dashboard.button("g", "  Find text", ":Telescope live_grep<CR>"),
          dashboard.button("c", "  Config", ":e ~/.config/nix/home/dev/nvim/appearance.nix<CR>"),
          dashboard.button("q", "  Quit", ":qa<CR>"),
        }

        require("alpha").setup(dashboard.opts)

        vim.api.nvim_create_autocmd("User", {
          pattern = "LazyVimStarted",
          callback = function()
            local theme = require("alpha.themes.startify")
            local stats = require("lazy").stats()
            local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
            theme.section.footer.val = "⚡ Neovim loaded " .. stats.count .. " plugins in " .. ms .. "ms"
            pcall(require("alpha").setup, theme.opts)
          end,
        })
      '';

      # Appearance-related plugins
      xdg_config."nvim/lua/plugins_appearance.lua".text = ''
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
              })
              vim.cmd.colorscheme("cyberdream")
            end,
          },

          -- Dashboard
          {
            "goolord/alpha-nvim",
            event = "VimEnter",
            config = function()
              require("dashboard")
            end,
            dependencies = { "nvim-tree/nvim-web-devicons" },
          },

          {
            "stevearc/dressing.nvim",
            event = "VeryLazy",
            opts = {},
          },

          -- UI
          {
            "folke/noice.nvim",
            event = "VeryLazy",
            opts = {
              presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = false,
              },
              views = {
                mini = {
                  win_options = {
                    winblend = 0,
                  },
                },
              },
            },
            dependencies = {
              "MunifTanjim/nui.nvim",
              "rcarriga/nvim-notify",
            },
            config = function(_, opts)
              require("noice").setup(opts)
            end,
          },

          -- Indent lines
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

          -- File management UI
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

          -- UI Enhancements
          {
            "nvim-lualine/lualine.nvim",
            event = "VeryLazy",
            dependencies = { "utilyre/barbecue.nvim" },
            opts = {
              options = {
                theme = "cyberdream",
                globalstatus = true,
                component_separators = { left = '', right = '' },
                section_separators = { left = '', right = '' },
              },
              sections = {
                lualine_a = { { "mode", fmt = function(str) return str:sub(1,1) end } },
                lualine_b = { "branch", "diff" },
                lualine_c = { { "filename", path = 1 } },
                lualine_x = { "diagnostics", "encoding", "filetype" },
                lualine_y = { "progress" },
                lualine_z = { "location" },
              },
              winbar = {
                lualine_c = {
                  {
                    "b:barbecue.get_context",
                    icon = "",
                  },
                },
              },
              inactive_winbar = {
                lualine_c = {
                  {
                    "b:barbecue.get_context",
                    icon = "",
                  },
                },
              },
            },
          },

          -- Git integration UI
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
        }
      '';
    };
  };
}
