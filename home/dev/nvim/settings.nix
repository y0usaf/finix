{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  username = "y0usaf";
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


        -- Keymaps
        local keymap = vim.keymap.set

        -- Telescope
        local builtin = require("telescope.builtin")
        keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
        keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
        keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
        keymap("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
        keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
        keymap("n", "<leader>fo", builtin.git_status, { desc = "Git status" })

        -- File explorer
        keymap("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File explorer" })

        -- Buffer navigation
        keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
        keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
        keymap("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

        -- Window navigation
        keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
        keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
        keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
        keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

        -- Utility
        keymap("n", "<leader>ut", "<cmd>Twilight<cr>", { desc = "Toggle twilight" })
        keymap("n", "<C-\\", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
        keymap("t", "<C-\\", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
        keymap("n", "zR", function() require("ufo").openAllFolds() end, { desc = "Open all folds" })
        keymap("n", "zM", function() require("ufo").closeAllFolds() end, { desc = "Close all folds" })
        keymap("n", "zr", function() require("ufo").openFoldsExceptKinds() end, { desc = "Open folds except kinds" })
        keymap("n", "zm", function() require("ufo").closeFoldsWith() end, { desc = "Close folds with" })
        keymap("n", "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, { desc = "Peek folded lines" })

        -- Diagnostics
        keymap("n", "<leader>xx", builtin.diagnostics, { desc = "Diagnostics" })
        keymap("n", "<leader>xd", function() builtin.diagnostics({ bufnr = 0 }) end, { desc = "Buffer diagnostics" })

        -- Leetcode
        keymap("n", "<leader>lq", "<cmd>Leet<cr>", { desc = "Leetcode menu" })
        keymap("n", "<leader>ll", "<cmd>Leet list<cr>", { desc = "Leetcode list" })
        keymap("n", "<leader>lt", "<cmd>Leet test<cr>", { desc = "Leetcode test" })
        keymap("n", "<leader>ls", "<cmd>Leet submit<cr>", { desc = "Leetcode submit" })
        keymap("n", "<leader>ln", "<cmd>messages<cr>", { desc = "View messages" })

        -- Basic
        keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
        keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
        keymap("n", "<leader>/", function() require("Comment.api").toggle.linewise.current() end, { desc = "Toggle comment" })
        keymap("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", { desc = "Toggle comment" })

        -- Better movement
        keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
        keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

        -- Move lines
        keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
        keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
        keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
        keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
        keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
        keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

        -- Indenting
        keymap("v", "<", "<gv")
        keymap("v", ">", ">gv")

        keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

        -- Auto-install treesitter parsers
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
