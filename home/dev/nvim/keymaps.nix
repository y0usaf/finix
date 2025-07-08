# Neovim keymaps module
{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/init.lua".text = lib.mkAfter ''
      -- Keymaps
      local keymap = vim.keymap.set

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

      -- Flash
      keymap({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })
      keymap({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash Treesitter" })

      -- Diagnostics
      keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle diagnostics" })
      keymap("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })

      -- Leetcode
      keymap("n", "<leader>lq", "<cmd>Leet<cr>", { desc = "Leetcode menu" })
      keymap("n", "<leader>ll", "<cmd>Leet list<cr>", { desc = "Leetcode list" })
      keymap("n", "<leader>lt", "<cmd>Leet test<cr>", { desc = "Leetcode test" })
      keymap("n", "<leader>ls", "<cmd>Leet submit<cr>", { desc = "Leetcode submit" })
      keymap("n", "<leader>ln", "<cmd>messages<cr>", { desc = "View messages" })

      -- Quick actions
      keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
      keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
      keymap("n", "<leader>/", function() require("Comment.api").toggle.linewise.current() end, { desc = "Toggle comment" })
      keymap("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", { desc = "Toggle comment" })

      -- Better up/down
      keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
      keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

      -- Move Lines
      keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
      keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
      keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
      keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
      keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
      keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

      -- Better indenting
      keymap("v", "<", "<gv")
      keymap("v", ">", ">gv")
    '';
  };
}
