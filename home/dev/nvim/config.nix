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
  
  # LSP servers and development tools
  lspPackages = with pkgs; [
    lua-language-server nil pyright rust-analyzer typescript-language-server
    vscode-langservers-extracted bash-language-server marksman yaml-language-server
    dockerfile-language-server-nodejs stylua alejandra black prettier rustfmt
  ];

  # Create MNW-based Neovim package
  mnwNeovim = inputs.mnw.lib.wrap pkgs {
    neovim = pkgs.neovim-unwrapped;
    initLua = "require('init')";
    
    plugins = {
      start = with pkgs.vimPlugins; [
        nvim-lspconfig nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path cmp_luasnip luasnip
        nvim-treesitter.withAllGrammars plenary-nvim nvim-web-devicons lualine-nvim
        indent-blankline-nvim which-key-nvim telescope-nvim telescope-fzf-native-nvim
        neo-tree-nvim bufferline-nvim nui-nvim gitsigns-nvim lazygit-nvim comment-nvim
        nvim-autopairs mini-indentscope conform-nvim trouble-nvim toggleterm-nvim persistence-nvim
      ];
    };
    
    extraBinPath = lspPackages;
  };
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [
        mnwNeovim pkgs.lazygit pkgs.ripgrep pkgs.fd pkgs.tree-sitter pkgs.fzf pkgs.bat pkgs.delta
      ];

      file.xdg_config = {
        "nvim/lua/init.lua".text = ''
          vim.g.mapleader = " "
          vim.g.maplocalleader = "\\"
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1
          vim.g.loaded_matchparen = 1

          require('config.options')
          require('config.keymaps') 
          require('config.theme')
          require('config.lsp')
          require('config.plugins')
          require('config.autocmds')
        '';

        "nvim/lua/config/options.lua".text = ''
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
        '';

        "nvim/lua/config/keymaps.lua".text = ''
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

          -- Buffer management
          keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
          keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
          keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

          -- Clear search highlighting
          keymap("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

          -- File explorer
          keymap("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
          keymap("n", "<leader>ge", ":Neotree git_status<CR>", { desc = "Git explorer" })

          -- Telescope
          keymap("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
          keymap("n", "<leader>fw", ":Telescope live_grep<CR>", { desc = "Find word" })
          keymap("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
          keymap("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Find help" })
          keymap("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Find recent files" })

          -- Git
          keymap("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
          keymap("n", "<leader>gb", ":Gitsigns blame_line<CR>", { desc = "Git blame line" })
          keymap("n", "<leader>gd", ":Gitsigns diffthis<CR>", { desc = "Git diff" })
          keymap("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })

          -- Trouble
          keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
          keymap("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })

          -- Terminal
          keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal (float)" })
          keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Terminal (horizontal)" })

          -- Formatting
          keymap("n", "<leader>mp", function() require("conform").format({ lsp_fallback = true }) end, { desc = "Format document" })
        '';

        "nvim/lua/config/theme.lua".text = ''
          -- Obsidian Elegance Theme
          local colors = {
            bg = "NONE",
            bg_highlight = "#1a1a25",
            bg_visual = "#2d2d42",
            fg = "#e8e8f0",
            fg_dark = "#c0c0d0",
            fg_gutter = "#4a4a60",
            blue = "#6bb6ff",
            cyan = "#4fd6be", 
            green = "#7dd65a",
            magenta = "#c68aee",
            red = "#ff6b85",
            orange = "#ffb347",
            yellow = "#f0c674",
            purple = "#b19cd9",
            border = "#404055",
            comment = "#6a6a80",
          }

          vim.cmd("highlight clear")
          if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
          vim.o.background = "dark"
          vim.g.colors_name = "obsidian_elegance"

          local function hl(group, opts)
            local cmd = "highlight " .. group
            if opts.fg then cmd = cmd .. " guifg=" .. opts.fg end
            if opts.bg then cmd = cmd .. " guibg=" .. opts.bg end
            if opts.style then cmd = cmd .. " gui=" .. opts.style end
            if opts.sp then cmd = cmd .. " guisp=" .. opts.sp end
            vim.cmd(cmd)
          end

          -- Base highlights
          hl("Normal", { fg = colors.fg, bg = colors.bg })
          hl("Comment", { fg = colors.comment, style = "italic" })
          hl("Constant", { fg = colors.orange, style = "bold" })
          hl("String", { fg = colors.green, style = "italic" })
          hl("Function", { fg = colors.blue, style = "bold" })
          hl("Keyword", { fg = colors.purple, style = "italic,bold" })
          hl("Type", { fg = colors.blue, style = "italic,bold" })
          
          -- UI elements
          hl("CursorLine", { bg = colors.bg_highlight })
          hl("CursorLineNr", { fg = colors.orange, style = "bold" })
          hl("LineNr", { fg = colors.fg_gutter })
          hl("Visual", { bg = colors.bg_visual })
          hl("Search", { fg = colors.bg, bg = colors.yellow, style = "bold" })
          
          -- Diagnostics
          hl("DiagnosticError", { fg = colors.red })
          hl("DiagnosticWarn", { fg = colors.orange })
          hl("DiagnosticInfo", { fg = colors.blue })
          hl("DiagnosticHint", { fg = colors.cyan })
        '';

        "nvim/lua/config/lsp.lua".text = ''
          local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
          local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
          
          if not lspconfig_ok then return end
          
          local capabilities = cmp_nvim_lsp_ok and cmp_nvim_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
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
                  checkOnSave = { command = "clippy" },
                },
              },
            },
            ts_ls = {},
            html = {},
            cssls = {},
            jsonls = {},
            bashls = {},
            marksman = {},
            yamlls = {},
            dockerls = {},
          }

          for server, config in pairs(servers) do
            config.capabilities = capabilities
            lspconfig[server].setup(config)
          end

          -- LSP keymaps
          vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(event)
              local opts = { buffer = event.buf }
              local keymap = vim.keymap.set
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

          -- Diagnostic configuration
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
        '';

        "nvim/lua/config/plugins.lua".text = ''
          -- Completion setup
          local cmp_ok, cmp = pcall(require, 'cmp')
          local luasnip_ok, luasnip = pcall(require, 'luasnip')
          
          if cmp_ok then
            cmp.setup({
              snippet = {
                expand = function(args)
                  if luasnip_ok then luasnip.lsp_expand(args.body) end
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
                  elseif luasnip_ok and luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                  else
                    fallback()
                  end
                end, {'i', 's'}),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif luasnip_ok and luasnip.jumpable(-1) then
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
              experimental = { ghost_text = true },
            })
          end

          -- Plugin configurations
          pcall(function() require("bufferline").setup() end)
          pcall(function() require("ibl").setup() end)
          pcall(function() require("mini.indentscope").setup() end)
          pcall(function() require("neo-tree").setup() end)
          pcall(function() require("telescope").setup() end)
          pcall(function() require("nvim-treesitter.configs").setup({ highlight = { enable = true } }) end)
          pcall(function() require("lualine").setup() end)
          pcall(function() require("which-key").setup() end)
          pcall(function() require("gitsigns").setup() end)
          pcall(function() require("nvim-autopairs").setup() end)
          pcall(function() require("Comment").setup() end)
          pcall(function() require("conform").setup({
            formatters_by_ft = {
              lua = { "stylua" },
              nix = { "alejandra" },
              python = { "black" },
              javascript = { "prettier" },
              typescript = { "prettier" },
              rust = { "rustfmt" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
          }) end)
          pcall(function() require("trouble").setup() end)
          pcall(function() require("toggleterm").setup() end)
          pcall(function() require("persistence").setup() end)
        '';

        "nvim/lua/config/autocmds.lua".text = ''
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
            command = ":%s/\\\\s\\\\+$//e",
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