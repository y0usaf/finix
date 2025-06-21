# Basic Neovim settings and bootstrap module
{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/init.lua".text = lib.mkBefore ''
      vim.g.mapleader = " "
      vim.g.maplocalleader = "\\"

      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git",
          "clone",
          "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable",
          lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      -- Enhanced vim options
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.signcolumn = "yes"
      -- Advanced line wrapping configuration
      vim.opt.wrap = true
      vim.opt.linebreak = true        -- Break at word boundaries
      vim.opt.breakindent = true      -- Preserve indentation
      vim.opt.showbreak = "↪ "         -- Visual indicator for wrapped lines
      vim.opt.textwidth = 0           -- Don't auto-break while typing
      vim.opt.expandtab = true
      vim.opt.tabstop = 2
      vim.opt.shiftwidth = 2
      vim.opt.clipboard = "unnamedplus"
      vim.opt.ignorecase = true
      vim.opt.smartcase = true
      vim.opt.termguicolors = true
      vim.opt.updatetime = 250
      vim.opt.timeoutlen = 300
      vim.opt.scrolloff = 8
      vim.opt.sidescrolloff = 8
      vim.opt.cursorline = true
      vim.opt.cursorlineopt = "both"
      vim.opt.mouse = "a"
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
      vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
      vim.opt.splitbelow = true
      vim.opt.splitright = true
      vim.opt.splitkeep = "screen"
      vim.opt.smoothscroll = true

      -- Auto-install missing parsers when entering buffer
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          local parsers = require("nvim-treesitter.parsers")
          local lang = parsers.get_buf_lang()
          if parsers.get_parser_configs()[lang] and not parsers.has_parser(lang) then
            vim.schedule(function()
              vim.cmd("TSInstall " .. lang)
            end)
          end
        end,
      })
    '';
  };
}
