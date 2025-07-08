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
            })
            vim.cmd.colorscheme("cyberdream")
          end,
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
        },
        { "stevearc/dressing.nvim", event = "VeryLazy", opts = {} },

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
