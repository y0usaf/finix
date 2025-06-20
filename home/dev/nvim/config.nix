###############################################################################
# Neovim Main Configuration
# Single file that generates modular Lua configuration
###############################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;


  # Simple Neovim with jetpack plugin manager
  simpleNeovim = pkgs.neovim;

in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [
        pkgs.lazygit pkgs.ripgrep pkgs.fd pkgs.tree-sitter pkgs.fzf pkgs.bat pkgs.delta 
        simpleNeovim
        # LSP servers for jetpack to use
        pkgs.lua-language-server pkgs.nil pkgs.pyright pkgs.rust-analyzer 
        pkgs.typescript-language-server pkgs.vscode-langservers-extracted
        pkgs.bash-language-server pkgs.marksman pkgs.yaml-language-server
        pkgs.dockerfile-language-server-nodejs pkgs.stylua pkgs.alejandra 
        pkgs.black pkgs.prettier pkgs.rustfmt
      ];

      # Jetpack-based Neovim configuration
      file.xdg_config = {
        "nvim/init.lua".text = ''
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
          
          -- Setup lazy with plugins
          require("lazy").setup({
            -- Theme (cyberpunk aesthetic)
            {
              "folke/tokyonight.nvim",
              lazy = false,
              priority = 1000,
              opts = {
                style = "storm",
                terminal_colors = true,
                styles = {
                  comments = { italic = true },
                  keywords = { italic = true },
                  functions = { bold = true },
                  variables = {},
                },
                on_colors = function(colors)
                  colors.bg = "#0d1117"
                  colors.bg_dark = "#010409"
                  colors.bg_float = "#161b22"
                  colors.bg_sidebar = "#161b22"
                end,
                on_highlights = function(highlights, colors)
                  highlights.Normal = { bg = colors.bg }
                  highlights.NormalFloat = { bg = colors.bg_float }
                  highlights.FloatBorder = { fg = colors.blue }
                end,
              },
              config = function(_, opts)
                require("tokyonight").setup(opts)
                vim.cmd.colorscheme("tokyonight-storm")
              end,
            },
            
            -- UI Enhancements
            {
              "nvim-lualine/lualine.nvim",
              event = "VeryLazy",
              opts = {
                options = {
                  theme = "tokyonight",
                  globalstatus = true,
                  component_separators = { left = "", right = "" },
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
            
            {
              "akinsho/bufferline.nvim",
              event = "VeryLazy",
              opts = {
                options = {
                  mode = "buffers",
                  diagnostics = "nvim_lsp",
                  show_buffer_close_icons = false,
                  show_close_icon = false,
                  color_icons = true,
                  separator_style = "slant",
                },
              },
            },
            
            -- LSP
            {
              "neovim/nvim-lspconfig",
              event = { "BufReadPre", "BufNewFile" },
              dependencies = {
                "hrsh7th/cmp-nvim-lsp",
              },
              config = function()
                local lspconfig = require("lspconfig")
                local capabilities = require("cmp_nvim_lsp").default_capabilities()
                
                local on_attach = function(client, bufnr)
                  local opts = { buffer = bufnr, silent = true }
                  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                end
                
                -- Setup servers
                local servers = { "lua_ls", "nil_ls", "pyright", "rust_analyzer", "tsserver", "bashls", "marksman" }
                for _, server in ipairs(servers) do
                  lspconfig[server].setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = server == "lua_ls" and {
                      Lua = { diagnostics = { globals = { "vim" } } }
                    } or {},
                  })
                end
              end,
            },
            
            -- Completion
            {
              "hrsh7th/nvim-cmp",
              event = "InsertEnter",
              dependencies = {
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "L3MON4D3/LuaSnip",
                "saadparwaiz1/cmp_luasnip",
              },
              config = function()
                local cmp = require("cmp")
                local luasnip = require("luasnip")
                
                cmp.setup({
                  snippet = {
                    expand = function(args)
                      luasnip.lsp_expand(args.body)
                    end,
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
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                  }, {
                    { name = "buffer" },
                    { name = "path" },
                  }),
                })
              end,
            },
            
            -- File management
            {
              "nvim-telescope/telescope.nvim",
              cmd = "Telescope",
              dependencies = { "nvim-lua/plenary.nvim" },
              opts = {
                defaults = {
                  file_ignore_patterns = { "node_modules", ".git/" },
                  layout_config = {
                    horizontal = { preview_width = 0.6 },
                  },
                },
              },
            },
            
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
            
            -- Git
            {
              "lewis6991/gitsigns.nvim",
              event = { "BufReadPre", "BufNewFile" },
              opts = {
                signs = {
                  add = { text = "▎" },
                  change = { text = "▎" },
                  delete = { text = "" },
                  topdelete = { text = "" },
                  changedelete = { text = "▎" },
                },
              },
            },
            
            -- Syntax highlighting
            {
              "nvim-treesitter/nvim-treesitter",
              build = ":TSUpdate",
              event = { "BufReadPost", "BufNewFile" },
              opts = {
                highlight = { enable = true },
                indent = { enable = true },
                ensure_installed = {
                  "lua", "nix", "python", "rust", "typescript", "javascript",
                  "bash", "markdown", "json", "yaml", "toml"
                },
              },
              config = function(_, opts)
                require("nvim-treesitter.configs").setup(opts)
              end,
            },
            
            -- Utilities
            { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
            { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
            { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
            {
              "lukas-reineke/indent-blankline.nvim",
              event = { "BufReadPost", "BufNewFile" },
              main = "ibl",
              opts = {
                indent = { char = "▏" },
                scope = { enabled = false },
              },
            },
            
            -- Terminal
            {
              "akinsho/toggleterm.nvim",
              cmd = { "ToggleTerm", "TermExec" },
              opts = {
                size = 20,
                open_mapping = [[<c-\>]],
                direction = "horizontal",
                shade_terminals = false,
              },
            },
            
            -- Diagnostics
            {
              "folke/trouble.nvim",
              cmd = { "Trouble", "TroubleToggle" },
              opts = { use_diagnostic_signs = true },
            },
          }, {
            ui = {
              border = "rounded",
              icons = {
                cmd = "⌘",
                config = "🛠",
                event = "📅",
                ft = "📂",
                init = "⚙",
                keys = "🗝",
                plugin = "🔌",
                runtime = "💻",
                source = "📄",
                start = "🚀",
                task = "📌",
              },
            },
          })
          
          -- Basic vim options
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.signcolumn = "yes"
          vim.opt.wrap = false
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
          vim.opt.mouse = "a"
          
          -- Keymaps
          local keymap = vim.keymap.set
          
          -- File operations
          keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
          keymap("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
          keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
          keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
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
          
          -- Diagnostics
          keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle diagnostics" })
          keymap("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
          
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
          
          print("🚀 Modern Neovim IDE loaded!")
        '';
      };
    };
  };
}
