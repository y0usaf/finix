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
                  -- Enhanced visual feedback
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

        -- Route notifications through fidget
        {
          "rcarriga/nvim-notify",
          event = "VeryLazy",
          config = function()
            -- Override vim.notify to use fidget
            vim.notify = function(msg, level, opts)
              local fidget = require("fidget")
              local level_map = {
                [vim.log.levels.ERROR] = "error",
                [vim.log.levels.WARN] = "warn",
                [vim.log.levels.INFO] = "info",
                [vim.log.levels.DEBUG] = "debug",
                [vim.log.levels.TRACE] = "trace",
              }

              fidget.notify(msg, {
                level = level_map[level] or "info",
                title = opts and opts.title or "Notification",
                key = opts and opts.key,
                on_open = opts and opts.on_open,
                on_close = opts and opts.on_close,
              })
            end
          end,
        },
        {
          "Bekaboo/dropbar.nvim",
          event = "VeryLazy",
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

        -- Window management for tiling WMs
        {
          "nvim-focus/focus.nvim",
          event = "VeryLazy",
          opts = {
            enable = true,
            commands = true,
            autoresize = {
              enable = true,
              width = 0,
              height = 0,
              minwidth = 0,
              minheight = 0,
              height_quickfix = 10,
            },
            split = {
              bufnew = false,
              tmux = false,
            },
            ui = {
              number = false,
              relativenumber = false,
              hybridnumber = false,
              absolutenumber_unfocussed = false,
              cursorline = true,
              cursorcolumn = false,
              colorcolumn = {
                enable = false,
                list = "+1",
              },
              signcolumn = true,
              winhighlight = false,
            },
          },
        },
        {
          "anuvyklack/windows.nvim",
          event = "VeryLazy",
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

        -- Statusline
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

        -- Git integration
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
      }
    '';
  };
}
