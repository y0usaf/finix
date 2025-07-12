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
      xdg_config."nvim/init.lua".text = ''

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
        vim.opt.pumheight = 15
        vim.opt.showmode = false
        vim.opt.laststatus = 2
        vim.opt.cmdheight = 1
        vim.opt.expandtab = true
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2
        vim.opt.clipboard = "unnamedplus"
        vim.opt.ignorecase = true
        vim.opt.smartcase = true
        vim.opt.updatetime = 250
        vim.opt.timeoutlen = 300
        vim.opt.mouse = "a"
        vim.opt.splitbelow = true
        vim.opt.splitright = true
        vim.opt.splitkeep = "screen"
        vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
        vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
        vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }


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


        local plugins = require("plugins")
        local appearance_plugins = require("plugins_appearance")
        for _, plugin in ipairs(appearance_plugins) do
          table.insert(plugins, plugin)
        end

        require("lazy").setup(plugins, {
          ui = { border = "rounded" },
        })


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
  };
}
