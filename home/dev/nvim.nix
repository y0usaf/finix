###############################################################################
# Enhanced Neovim Configuration (Standard dotfiles approach)
# Modern, reproducible Neovim setup with LSP and productivity tools
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # LSP servers and development tools
  lspPackages = with pkgs; [
    # Language servers
    lua-language-server
    nil # Nix LSP
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted # html, css, json
    bash-language-server
    marksman # Markdown LSP
    
    # Formatters
    stylua
    alejandra
    black
    prettier
    rustfmt
  ];
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced Neovim editor with modern features";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };

  ###########################################################################
  # Module Configuration - nix-maid packages and dotfiles
  ###########################################################################
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        # Enhanced terminal tools for Neovim workflow
        lazygit
        ripgrep
        fd
        tree-sitter
        
        # Standard Neovim package
        neovim
      ] ++ lspPackages ++ lib.optionals cfg.neovide [
        neovide
      ];

      # Dotfiles configuration
      file.home = {
        ".config/nvim/init.lua".text = ''
          -- ============================================================================
          -- Enhanced Neovim Configuration
          -- Modern, feature-rich setup with LSP, completion, and productivity tools
          -- ============================================================================

          -- Set leader keys early
          vim.g.mapleader = " "
          vim.g.maplocalleader = "\\"

          -- Disable builtin plugins
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1
          vim.g.loaded_matchparen = 1

          -- ============================================================================
          -- BOOTSTRAP LAZY.NVIM
          -- ============================================================================

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

          -- ============================================================================
          -- OPTIONS
          -- ============================================================================

          local opt = vim.opt

          -- General
          opt.clipboard = "unnamedplus"
          opt.mouse = "a"
          opt.undofile = true
          opt.undolevels = 10000
          opt.backup = false
          opt.writebackup = false
          opt.swapfile = false

          -- UI
          opt.number = true
          opt.relativenumber = true
          opt.signcolumn = "yes:2"
          opt.cursorline = true
          opt.termguicolors = true
          opt.background = "dark"
          opt.conceallevel = 2
          opt.showmode = false
          opt.laststatus = 3
          opt.showtabline = 2
          opt.cmdheight = 0
          opt.pumheight = 10
          opt.pumblend = 10
          opt.winblend = 10

          -- Editing
          opt.expandtab = true
          opt.tabstop = 2
          opt.shiftwidth = 2
          opt.softtabstop = 2
          opt.autoindent = true
          opt.smartindent = true
          opt.wrap = false

          -- Search
          opt.ignorecase = true
          opt.smartcase = true
          opt.hlsearch = true
          opt.incsearch = true
          opt.grepprg = "rg --vimgrep"

          -- Performance
          opt.updatetime = 250
          opt.timeoutlen = 300
          opt.lazyredraw = true
          opt.synmaxcol = 240

          -- Splits
          opt.splitright = true
          opt.splitbelow = true
          opt.scrolloff = 8
          opt.sidescrolloff = 8

          -- Visual
          opt.list = true
          opt.listchars = "tab:→ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨"
          opt.fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸"

          -- Completion
          opt.completeopt = "menu,menuone,noselect"

          -- ============================================================================
          -- KEYMAPS
          -- ============================================================================

          local keymap = vim.keymap.set

          -- Better escape
          keymap("i", "jk", "<Esc>", { desc = "Exit insert mode" })

          -- Window navigation
          keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
          keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
          keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
          keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

          -- Window resizing
          keymap("n", "<C-Up>", ":resize -2<CR>", { desc = "Resize window up" })
          keymap("n", "<C-Down>", ":resize +2<CR>", { desc = "Resize window down" })
          keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize window left" })
          keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize window right" })

          -- Buffer navigation
          keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
          keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
          keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

          -- Clear search highlighting
          keymap("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

          -- ============================================================================
          -- LAZY.NVIM PLUGIN SETUP
          -- ============================================================================

          require("lazy").setup({
            -- Core functionality
            {
              "nvim-tree/nvim-web-devicons",
              lazy = true,
            },
            {
              "nvim-lua/plenary.nvim",
              lazy = true,
            },

            -- LSP and completion
            {
              "neovim/nvim-lspconfig",
              event = { "BufReadPre", "BufNewFile" },
              dependencies = {
                "hrsh7th/cmp-nvim-lsp",
              },
              config = function()
                local lspconfig = require('lspconfig')
                local capabilities = require('cmp_nvim_lsp').default_capabilities()

                -- Enhanced capabilities
                capabilities.textDocument.completion.completionItem.snippetSupport = true

                -- LSP servers setup
                local servers = {
                  lua_ls = {
                    settings = {
                      Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = { 'vim' } },
                        workspace = {
                          library = vim.api.nvim_get_runtime_file("", true),
                          checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                      },
                    },
                  },
                  nil_ls = {},
                  pyright = {},
                  rust_analyzer = {
                    settings = {
                      ["rust-analyzer"] = {
                        cargo = { buildScripts = { enable = true } },
                        procMacro = { enable = true },
                      },
                    },
                  },
                  ts_ls = {},
                  html = {},
                  cssls = {},
                  jsonls = {},
                  bashls = {},
                  marksman = {},
                }

                for server, config in pairs(servers) do
                  config.capabilities = capabilities
                  lspconfig[server].setup(config)
                end

                -- LSP keymaps
                vim.api.nvim_create_autocmd('LspAttach', {
                  callback = function(event)
                    local opts = { buffer = event.buf }
                    keymap("n", "gd", ":Telescope lsp_definitions<CR>", opts)
                    keymap("n", "gr", ":Telescope lsp_references<CR>", opts)
                    keymap("n", "gi", ":Telescope lsp_implementations<CR>", opts)
                    keymap("n", "gt", ":Telescope lsp_type_definitions<CR>", opts)
                    keymap("n", "K", vim.lsp.buf.hover, opts)
                    keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    keymap("n", "<leader>d", vim.diagnostic.open_float, opts)
                    keymap("n", "[d", vim.diagnostic.goto_prev, opts)
                    keymap("n", "]d", vim.diagnostic.goto_next, opts)
                  end,
                })
              end,
            },

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
                local cmp = require('cmp')
                local luasnip = require('luasnip')

                cmp.setup({
                  snippet = {
                    expand = function(args)
                      luasnip.lsp_expand(args.body)
                    end,
                  },
                  sources = cmp.config.sources({
                    { name = 'nvim_lsp', priority = 1000 },
                    { name = 'luasnip', priority = 750 },
                    { name = 'buffer', priority = 500 },
                    { name = 'path', priority = 250 },
                  }),
                  mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                      else
                        fallback()
                      end
                    end, {'i', 's'}),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_prev_item()
                      elseif luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                      else
                        fallback()
                      end
                    end, {'i', 's'}),
                  }),
                  window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                  },
                  experimental = {
                    ghost_text = true,
                  },
                })
              end,
            },

            -- File navigation
            {
              "nvim-neo-tree/neo-tree.nvim",
              branch = "v3.x",
              dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-tree/nvim-web-devicons",
                "MunifTanjim/nui.nvim",
              },
              keys = {
                { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle file explorer" },
              },
              config = function()
                require('neo-tree').setup({
                  close_if_last_window = true,
                  enable_git_status = true,
                  enable_diagnostics = true,
                  window = {
                    width = 35,
                    mappings = {
                      ["<space>"] = "none",
                    },
                  },
                  filesystem = {
                    follow_current_file = {
                      enabled = true,
                    },
                    use_libuv_file_watcher = true,
                  },
                })
              end,
            },

            {
              "nvim-telescope/telescope.nvim",
              tag = "0.1.8",
              dependencies = {
                "nvim-lua/plenary.nvim",
                { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
              },
              keys = {
                { "<leader>ff", ":Telescope find_files<CR>", desc = "Find files" },
                { "<leader>fw", ":Telescope live_grep<CR>", desc = "Find word" },
                { "<leader>fb", ":Telescope buffers<CR>", desc = "Find buffers" },
                { "<leader>fh", ":Telescope help_tags<CR>", desc = "Find help" },
                { "<leader>fr", ":Telescope oldfiles<CR>", desc = "Find recent files" },
              },
              config = function()
                require('telescope').setup({
                  defaults = {
                    file_ignore_patterns = { "node_modules", ".git", "target", "build" },
                    vimgrep_arguments = {
                      "rg", "--color=never", "--no-heading", "--with-filename",
                      "--line-number", "--column", "--smart-case"
                    },
                  },
                  extensions = {
                    fzf = {
                      fuzzy = true,
                      override_generic_sorter = true,
                      override_file_sorter = true,
                      case_mode = "smart_case",
                    }
                  }
                })
                pcall(require('telescope').load_extension, 'fzf')
              end,
            },

            -- Syntax and editing
            {
              "nvim-treesitter/nvim-treesitter",
              build = ":TSUpdate",
              event = { "BufReadPost", "BufNewFile" },
              config = function()
                require('nvim-treesitter.configs').setup({
                  ensure_installed = {
                    "lua", "nix", "python", "rust", "typescript", "javascript",
                    "html", "css", "json", "yaml", "bash", "markdown"
                  },
                  highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                  },
                  indent = {
                    enable = true,
                  },
                  incremental_selection = {
                    enable = true,
                    keymaps = {
                      init_selection = "<C-space>",
                      node_incremental = "<C-space>",
                      scope_incremental = false,
                      node_decremental = "<bs>",
                    },
                  },
                })
              end,
            },

            -- UI and statusline
            {
              "nvim-lualine/lualine.nvim",
              event = "VeryLazy",
              dependencies = { "nvim-tree/nvim-web-devicons" },
              config = function()
                require('lualine').setup({
                  options = {
                    theme = 'auto',
                    globalstatus = true,
                    component_separators = { left = '|', right = '|' },
                    section_separators = { left = '''', right = '''' },
                  },
                  sections = {
                    lualine_a = {'mode'},
                    lualine_b = {'branch', 'diff', 'diagnostics'},
                    lualine_c = {{'filename', path = 1}},
                    lualine_x = {'encoding', 'fileformat', 'filetype'},
                    lualine_y = {'progress'},
                    lualine_z = {'location'}
                  },
                })
              end,
            },

            {
              "folke/which-key.nvim",
              event = "VeryLazy",
              config = function()
                require('which-key').setup({
                  plugins = {
                    spelling = { enabled = true, suggestions = 20 },
                  },
                })
              end,
            },

            -- Git integration
            {
              "lewis6991/gitsigns.nvim",
              event = { "BufReadPre", "BufNewFile" },
              config = function()
                require('gitsigns').setup({
                  signs = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '_' },
                    topdelete = { text = '‾' },
                    changedelete = { text = '~' },
                  },
                })
              end,
            },

            {
              "kdheepak/lazygit.nvim",
              keys = {
                { "<leader>gg", ":LazyGit<CR>", desc = "Open LazyGit" },
              },
              dependencies = {
                "nvim-lua/plenary.nvim",
              },
            },

            -- Editing enhancements
            {
              "windwp/nvim-autopairs",
              event = "InsertEnter",
              config = function()
                require('nvim-autopairs').setup({
                  check_ts = true,
                  ts_config = {
                    lua = {'string', 'source'},
                    javascript = {'string', 'template_string'},
                  },
                })
              end,
            },

            {
              "numToStr/Comment.nvim",
              keys = {
                { "gcc", mode = "n" },
                { "gc", mode = "v" },
              },
              config = function()
                require('Comment').setup()
              end,
            },

            -- Formatting
            {
              "stevearc/conform.nvim",
              event = { "BufReadPre", "BufNewFile" },
              keys = {
                { "<leader>mp", function() require("conform").format({ lsp_fallback = true }) end, desc = "Format document" },
              },
              config = function()
                require('conform').setup({
                  formatters_by_ft = {
                    lua = { "stylua" },
                    nix = { "alejandra" },
                    python = { "black" },
                    javascript = { "prettier" },
                    typescript = { "prettier" },
                    rust = { "rustfmt" },
                    html = { "prettier" },
                    css = { "prettier" },
                    json = { "prettier" },
                    markdown = { "prettier" },
                  },
                  format_on_save = {
                    timeout_ms = 500,
                    lsp_fallback = true,
                  },
                })
              end,
            },
          })

          -- ============================================================================
          -- DIAGNOSTICS CONFIGURATION
          -- ============================================================================

          vim.diagnostic.config({
            virtual_text = {
              enabled = true,
              prefix = "●",
              severity = vim.diagnostic.severity.ERROR,
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
              border = "rounded",
              source = "always",
              header = "",
              prefix = "",
            },
          })

          -- LSP diagnostic signs
          local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
          for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
          end

          -- ============================================================================
          -- AUTOCOMMANDS
          -- ============================================================================

          local augroup = vim.api.nvim_create_augroup
          local autocmd = vim.api.nvim_create_autocmd

          -- Highlight on yank
          augroup("YankHighlight", { clear = true })
          autocmd("TextYankPost", {
            group = "YankHighlight",
            callback = function()
              vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
            end,
          })

          -- Remove whitespace on save
          augroup("RemoveWhitespace", { clear = true })
          autocmd("BufWritePre", {
            group = "RemoveWhitespace",
            pattern = "*",
            command = ":%s/\\s\\+$//e",
          })

          -- Close certain windows with q
          augroup("CloseWithQ", { clear = true })
          autocmd("FileType", {
            group = "CloseWithQ",
            pattern = { "help", "startuptime", "qf", "lspinfo" },
            command = "nnoremap <buffer><silent> q :close<CR>",
          })

          -- Auto-resize splits when vim is resized
          augroup("AutoResize", { clear = true })
          autocmd("VimResized", {
            group = "AutoResize",
            command = "tabdo wincmd =",
          })
        '';
      };
    };
  };
}