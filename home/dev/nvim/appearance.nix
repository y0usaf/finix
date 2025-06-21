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
        vim.opt.pumblend = 15
        vim.opt.winblend = 15
        vim.opt.conceallevel = 2
        vim.opt.concealcursor = "niv"
        vim.opt.showmode = false
        vim.opt.laststatus = 3
        vim.opt.cmdheight = 0
        vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
        vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
        vim.opt.smoothscroll = true
      '';

      # Appearance-related plugins
      xdg_config."nvim/lua/plugins_appearance.lua".text = ''
        return {
          -- Theme
          {
            "folke/tokyonight.nvim",
            lazy = false,
            priority = 1000,
            opts = {
              style = "night",
              transparent = true,
              terminal_colors = true,
              styles = {
                comments = { italic = true },
                keywords = { italic = true },
                functions = { bold = true },
                variables = {},
                sidebars = "transparent",
                floats = "transparent",
              },
              sidebars = { "qf", "help", "vista_kind", "terminal", "packer" },
              day_brightness = 0.3,
              hide_inactive_statusline = false,
              dim_inactive = false,
              lualine_bold = true,
              on_colors = function(colors)
                colors.border = "#1a1b26"
                colors.bg_statusline = "#16161e"
              end,
              on_highlights = function(highlights, colors)
                highlights.CursorLineNr = { fg = colors.orange, bold = true }
                highlights.LineNr = { fg = colors.dark3 }
                highlights.FloatBorder = { fg = colors.border_highlight }
                highlights.TelescopeBorder = { fg = colors.border_highlight }
                highlights.WhichKeyFloat = { bg = colors.bg_dark }
                highlights.LspFloatWinBorder = { fg = colors.border_highlight }
              end,
            },
            config = function(_, opts)
              require("tokyonight").setup(opts)
              vim.cmd.colorscheme("tokyonight-night")
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

          -- UI Enhancements
          {
            "nvim-lualine/lualine.nvim",
            event = "VeryLazy",
            opts = {
              options = {
                theme = "tokyonight",
                globalstatus = true,
                component_separators = { left = "│", right = "│" },
                section_separators = { left = "", right = "" },
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
