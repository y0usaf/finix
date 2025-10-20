{
  config,
  lib,
  ...
}: {
  imports = [
    ./neovide.nix
    ./options.nix
    ./packages.nix
  ];

  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      # Core nvim configuration using text approach (hjem doesn't require generator for text)
      ".config/nvim/init.lua".text = ''
        -- Leader keys
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        -- Load plugins
        vim.pack.add({
          -- Core dependencies
          "https://github.com/nvim-lua/plenary.nvim",
          "https://github.com/nvim-tree/nvim-web-devicons",
          "https://github.com/MunifTanjim/nui.nvim",

          -- File navigation
          "https://github.com/nvim-neo-tree/neo-tree.nvim",

          -- Telescope
          "https://github.com/nvim-telescope/telescope.nvim",
          "https://github.com/nvim-telescope/telescope-fzf-native.nvim",

          -- LSP and Completion
          "https://github.com/neovim/nvim-lspconfig",
          "https://github.com/hrsh7th/nvim-cmp",
          "https://github.com/hrsh7th/cmp-nvim-lsp",
          "https://github.com/hrsh7th/cmp-buffer",
          "https://github.com/hrsh7th/cmp-path",
          "https://github.com/L3MON4D3/LuaSnip",
          "https://github.com/saadparwaiz1/cmp_luasnip",
          "https://github.com/onsails/lspkind.nvim",
          "https://git.sr.ht/~whynothugo/lsp_lines.nvim",

          -- Treesitter
          "https://github.com/nvim-treesitter/nvim-treesitter",

          -- Utilities
          "https://github.com/numToStr/Comment.nvim",
          "https://github.com/windwp/nvim-autopairs",
          "https://github.com/kevinhwang91/nvim-ufo",
          "https://github.com/kevinhwang91/promise-async",
          "https://github.com/j-hui/fidget.nvim",
          "https://github.com/RRethy/vim-illuminate",
          "https://github.com/folke/twilight.nvim",
          "https://github.com/akinsho/toggleterm.nvim",

          -- Theme & UI
          "https://github.com/scottmckendry/cyberdream.nvim",
          "https://github.com/Bekaboo/dropbar.nvim",
          "https://github.com/stevearc/dressing.nvim",
          "https://github.com/anuvyklack/windows.nvim",
          "https://github.com/anuvyklack/middleclass",
          "https://github.com/nvim-lualine/lualine.nvim",
          "https://github.com/lewis6991/gitsigns.nvim",
          "https://github.com/lukas-reineke/indent-blankline.nvim",
          "https://github.com/folke/flash.nvim",
          "https://github.com/echasnovski/mini.hipatterns",

          -- Specialized
          "https://github.com/kawre/leetcode.nvim",
          "https://github.com/gelguy/wilder.nvim",
        })

        -- Line numbers and UI
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

        -- Indentation
        vim.opt.expandtab = true
        vim.opt.tabstop = 2
        vim.opt.shiftwidth = 2

        -- System integration
        vim.opt.clipboard = "unnamedplus"
        vim.opt.mouse = "a"

        -- Search
        vim.opt.ignorecase = true
        vim.opt.smartcase = true

        -- Timing
        vim.opt.updatetime = 250
        vim.opt.timeoutlen = 300

        -- Splits
        vim.opt.splitbelow = true
        vim.opt.splitright = true
        vim.opt.splitkeep = "screen"
        vim.opt.virtualedit = "onemore"

        -- Additional UI options
        vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
        vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
        vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

        -- Disable netrw for neo-tree
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- UFO folding settings
        vim.opt.foldcolumn = "1"
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true

        -- Neo-tree setup
        require("neo-tree").setup({
          close_if_last_window = true,
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          default_component_configs = {
            indent = {
              indent_size = 2,
              padding = 1,
            },
            icon = {
              folder_closed = "",
              folder_open = "",
              folder_empty = "ﰊ",
              default = "*",
            },
            git_status = {
              symbols = {
                added = "✚",
                deleted = "✖",
                modified = "",
                renamed = "",
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
              }
            },
          },
          window = {
            position = "left",
            width = 40,
            mappings = {
              ["<space>"] = "toggle_node",
              ["<2-LeftMouse>"] = "open",
              ["<cr>"] = "open",
              ["o"] = "open",
              ["S"] = "open_split",
              ["s"] = "open_vsplit",
              ["t"] = "open_tabnew",
              ["C"] = "close_node",
              ["a"] = "add",
              ["A"] = "add_directory",
              ["d"] = "delete",
              ["r"] = "rename",
              ["y"] = "copy_to_clipboard",
              ["x"] = "cut_to_clipboard",
              ["p"] = "paste_from_clipboard",
              ["c"] = "copy",
              ["m"] = "move",
              ["q"] = "close_window",
              ["R"] = "refresh",
            }
          },
          filesystem = {
            filtered_items = {
              visible = false,
              hide_dotfiles = false,
              hide_gitignored = false,
            },
            follow_current_file = {
              enabled = true,
            },
            use_libuv_file_watcher = true,
          },
          git_status = {
            window = {
              position = "float",
              mappings = {
                ["A"] = "git_add_all",
                ["gu"] = "git_unstage_file",
                ["ga"] = "git_add_file",
                ["gr"] = "git_revert_file",
                ["gc"] = "git_commit",
                ["gp"] = "git_push",
                ["gg"] = "git_commit_and_push",
              }
            }
          }
        })

        -- Plugin configurations
        -- Telescope setup
        require("telescope").setup({})
        pcall(require("telescope").load_extension, "fzf")

        -- LSP setup
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        require("lsp_lines").setup()
        vim.diagnostic.config({ virtual_text = false })

        local on_attach = function(client, bufnr)
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          vim.keymap.set("n", "<leader>l", require("lsp_lines").toggle, opts)
        end

        local servers = { "lua_ls", "nil_ls", "pyright" }
        for _, server in ipairs(servers) do
          lspconfig[server].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = server == "lua_ls" and {
              Lua = { diagnostics = { globals = { "vim" } } }
            } or {},
          })
        end

        -- Completion setup
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")
        cmp.setup({
          snippet = {
            expand = function(args) luasnip.lsp_expand(args.body) end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp", priority = 1000 },
            { name = "luasnip", priority = 750 },
          }, {
            { name = "buffer", priority = 500, max_item_count = 5 },
            { name = "path", priority = 250, max_item_count = 3 },
          }),
          formatting = {
            format = lspkind.cmp_format({
              mode = "symbol_text",
              maxwidth = 50,
              ellipsis_char = "...",
            }),
          },
        })

        -- Other plugin setups
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
          indent = { enable = true },
        })

        require("cyberdream").setup({
          transparent = true,
          italic_comments = true,
          borderless_pickers = true,
          lualine_style = "default",
          theme = {
            variant = "default",
            highlights = {
              -- Core UI colors matching neon dark theme
              Normal = { bg = "#0f0f0f", fg = "#ffffff" },
              NormalNC = { bg = "#0f0f0f", fg = "#b4b4b4" },

              -- Active/focused elements (neon green)
              CursorLine = { bg = "#1a1a1a" },
              Visual = { bg = "#003d2a" },
              Search = { bg = "#00ff96", fg = "#000000" },
              IncSearch = { bg = "#00ff64", fg = "#000000" },

              -- Errors and warnings (neon pink/orange)
              Error = { fg = "#ff0064" },
              ErrorMsg = { fg = "#ff0064" },
              WarningMsg = { fg = "#ff6400" },
              DiagnosticError = { fg = "#ff0064" },
              DiagnosticWarn = { fg = "#ff6400" },

              -- Success states (neon green)
              DiagnosticOk = { fg = "#00ff64" },
              DiagnosticHint = { fg = "#00ff96" },

              -- Highlights and info (neon cyan)
              DiagnosticInfo = { fg = "#00c8ff" },
              Comment = { fg = "#808080", italic = true },

              -- Syntax highlighting with neon accents
              String = { fg = "#00ff64" },
              Function = { fg = "#00c8ff" },
              Keyword = { fg = "#c800ff" },
              Type = { fg = "#00ff96" },
              Constant = { fg = "#ff6400" },
              Special = { fg = "#ff007f" },

              -- UI borders and separators
              FloatBorder = { fg = "#00ff96" },
              WinSeparator = { fg = "#404040" },

              -- Tab line
              TabLine = { bg = "#1a1a1a", fg = "#808080" },
              TabLineSel = { bg = "#00ff96", fg = "#000000" },

              -- Status line
              StatusLine = { bg = "#1a1a1a", fg = "#ffffff" },
              StatusLineNC = { bg = "#0f0f0f", fg = "#808080" },

              -- Popup menus
              Pmenu = { bg = "#1a1a1a", fg = "#ffffff" },
              PmenuSel = { bg = "#00ff96", fg = "#000000" },
              PmenuBorder = { fg = "#00ff96" },
            },
          },
        })
        vim.cmd.colorscheme("cyberdream")

        require("lualine").setup({ options = { theme = "cyberdream", globalstatus = true } })
        require("gitsigns").setup({ current_line_blame = true })
        require("ibl").setup({})
        require("Comment").setup({})
        require("nvim-autopairs").setup({})
        require("ufo").setup({})
        require("fidget").setup({})
        require("illuminate").configure({})
        require("twilight").setup({})
        require("toggleterm").setup({ direction = "float" })
        require("flash").setup({})
        require("mini.hipatterns").setup({})
        require("dropbar").setup({})
        require("dressing").setup({})
        require("windows").setup({})

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
      '';
    };
  };
}
