# Keymaps for Neovim - shared across all systems
# Returns Lua code for all keybindings
''
  -- Keymaps setup
  local keymap = vim.keymap.set
  local builtin = require("telescope.builtin")

  -- Telescope keymaps
  keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
  keymap("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
  keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
  keymap("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
  keymap("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
  keymap("n", "<leader>fo", builtin.git_status, { desc = "Git status" })

  -- File navigation with neo-tree
  keymap("n", "-", "<cmd>Neotree toggle<cr>", { desc = "Toggle neo-tree" })
  keymap("n", "<leader>-", "<cmd>Neotree focus<cr>", { desc = "Focus neo-tree" })
  keymap("n", "<leader>e", "<cmd>Neotree reveal<cr>", { desc = "Reveal file in neo-tree" })

  -- Buffer navigation
  keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
  keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
  keymap("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

  -- Window navigation
  keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
  keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
  keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
  keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

  -- Utility keymaps
  keymap("n", "<leader>ut", "<cmd>Twilight<cr>", { desc = "Toggle twilight" })
  keymap("n", "<C-\\", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
  keymap("t", "<C-\\", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })

  -- UFO fold keymaps
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

  -- Basic keymaps
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
''
