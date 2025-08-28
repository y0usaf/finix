{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
in {
  config = lib.mkIf cfg.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua" = {
        clobber = true;
        text = ''
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
          vim.opt.virtualedit = "onemore"
          vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
          vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
          vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
          -- UFO folding settings
          vim.opt.foldcolumn = "1"
          vim.opt.foldlevel = 99
          vim.opt.foldlevelstart = 99
          vim.opt.foldenable = true
          -- Load vim.pack configuration
          require("vim-pack-config")

          -- Load opencode configuration if available
          pcall(require, "vim-pack-opencode")
          pcall(require, "opencode-config")
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
          -- File navigation
          keymap("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
          keymap("n", "<leader>-", "<CMD>Oil .<CR>", { desc = "Open current directory" })
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
          keymap("n", "<leader>uh", function() require("hardtime").toggle() end, { desc = "Toggle hardtime" })
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
          -- Disable auto-install treesitter parsers (managed by nix)
          -- vim.api.nvim_create_autocmd("FileType", {
          --   callback = function()
          --     local parsers = require("nvim-treesitter.parsers")
          --     local lang = parsers.get_buf_lang()
          --     if parsers.get_parser_configs()[lang] and not parsers.has_parser(lang) then
          --       vim.schedule(function()
          --         vim.cmd("TSInstall " .. lang)
          --       end)
          --     end
          --   end,
          -- })
        '';
      };
    };
  };
}
