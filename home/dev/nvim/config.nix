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
          
          -- Bootstrap jetpack
          local jetpack_path = vim.fn.stdpath('data') .. '/site/pack/jetpack/opt/vim-jetpack'
          if vim.fn.empty(vim.fn.glob(jetpack_path)) > 0 then
            vim.fn.system({
              'git', 'clone', '--depth', '1',
              'https://github.com/tani/vim-jetpack',
              jetpack_path
            })
          end
          
          -- Add jetpack to runtime path and load it
          vim.cmd('packadd vim-jetpack')
          
          -- Load jetpack and setup plugins
          require('jetpack').startup(function(use)
            -- Plugin manager
            use 'tani/vim-jetpack'
            
            -- LSP and completion
            use 'neovim/nvim-lspconfig'
            use 'hrsh7th/nvim-cmp'
            use 'hrsh7th/cmp-nvim-lsp'
            use 'hrsh7th/cmp-buffer'
            use 'hrsh7th/cmp-path'
            use 'L3MON4D3/LuaSnip'
            use 'saadparwaiz1/cmp_luasnip'
            
            -- File management
            use 'nvim-lua/plenary.nvim'
            use 'nvim-telescope/telescope.nvim'
            use 'nvim-neo-tree/neo-tree.nvim'
            use 'MunifTanjim/nui.nvim'
            use 'nvim-tree/nvim-web-devicons'
            
            -- UI enhancements
            use 'nvim-lualine/lualine.nvim'
            use 'akinsho/bufferline.nvim'
            use 'lukas-reineke/indent-blankline.nvim'
            use 'folke/which-key.nvim'
            use 'goolord/alpha-nvim'
            use 'rcarriga/nvim-notify'
            use 'stevearc/dressing.nvim'
            
            -- Git integration
            use 'lewis6991/gitsigns.nvim'
            use 'kdheepak/lazygit.nvim'
            
            -- Syntax and treesitter
            use 'nvim-treesitter/nvim-treesitter'
            use 'nvim-treesitter/nvim-treesitter-textobjects'
            
            -- Utilities
            use 'numToStr/Comment.nvim'
            use 'windwp/nvim-autopairs'
            use 'folke/trouble.nvim'
            use 'akinsho/toggleterm.nvim'
            use 'folke/todo-comments.nvim'
            
            -- Themes
            use 'folke/tokyonight.nvim'
            use 'catppuccin/nvim'
          end)
          
          -- Theme setup
          vim.cmd.colorscheme('tokyonight-night')
          
          -- Basic vim options
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.signcolumn = 'yes'
          vim.opt.wrap = false
          vim.opt.expandtab = true
          vim.opt.tabstop = 2
          vim.opt.shiftwidth = 2
          vim.opt.clipboard = 'unnamedplus'
          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.termguicolors = true
          vim.opt.updatetime = 250
          vim.opt.timeoutlen = 300
          
          -- Lualine statusline
          require('lualine').setup({
            options = {
              theme = 'tokyonight',
              component_separators = '|',
              section_separators = { left = ' ', right = ' ' },
            },
            sections = {
              lualine_a = {'mode'},
              lualine_b = {'branch', 'diff', 'diagnostics'},
              lualine_c = {'filename'},
              lualine_x = {'encoding', 'fileformat', 'filetype'},
              lualine_y = {'progress'},
              lualine_z = {'location'}
            }
          })
          
          -- Bufferline
          require('bufferline').setup({
            options = {
              diagnostics = 'nvim_lsp',
              offsets = {
                {
                  filetype = 'neo-tree',
                  text = 'File Explorer',
                  text_align = 'center',
                }
              }
            }
          })
          
          -- Which-key for keybind help
          require('which-key').setup()
          
          -- Indent guides
          require('ibl').setup()
          
          -- Auto pairs
          require('nvim-autopairs').setup()
          
          -- Comments
          require('Comment').setup()
          
          -- Git signs
          require('gitsigns').setup({
            signs = {
              add = { text = '+' },
              change = { text = '~' },
              delete = { text = '_' },
              topdelete = { text = '‾' },
              changedelete = { text = '~' },
            }
          })
          
          -- Neo-tree file explorer
          require('neo-tree').setup({
            window = {
              width = 30,
            },
            filesystem = {
              filtered_items = {
                hide_dotfiles = false,
                hide_gitignored = false,
              }
            }
          })
          
          -- Telescope fuzzy finder
          require('telescope').setup({
            defaults = {
              mappings = {
                i = {
                  ['<C-u>'] = false,
                  ['<C-d>'] = false,
                }
              }
            }
          })
          
          -- Treesitter syntax highlighting
          require('nvim-treesitter.configs').setup({
            highlight = { enable = true },
            indent = { enable = true },
            textobjects = {
              select = {
                enable = true,
                lookahead = true,
                keymaps = {
                  ['af'] = '@function.outer',
                  ['if'] = '@function.inner',
                  ['ac'] = '@class.outer',
                  ['ic'] = '@class.inner',
                }
              }
            }
          })
          
          -- LSP setup with better diagnostics
          vim.diagnostic.config({
            virtual_text = true,
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
          })
          
          local lsp = require('lspconfig')
          local capabilities = require('cmp_nvim_lsp').default_capabilities()
          
          -- Enhanced LSP on_attach function
          local on_attach = function(client, bufnr)
            local opts = { buffer = bufnr, silent = true }
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, opts)
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
          end
          
          -- Setup LSP servers
          lsp.lua_ls.setup{ 
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                diagnostics = { globals = {'vim'} }
              }
            }
          }
          lsp.nil_ls.setup{ capabilities = capabilities, on_attach = on_attach }
          lsp.pyright.setup{ capabilities = capabilities, on_attach = on_attach }
          lsp.rust_analyzer.setup{ capabilities = capabilities, on_attach = on_attach }
          lsp.tsserver.setup{ capabilities = capabilities, on_attach = on_attach }
          lsp.bashls.setup{ capabilities = capabilities, on_attach = on_attach }
          lsp.marksman.setup{ capabilities = capabilities, on_attach = on_attach }
          
          -- Enhanced completion
          local cmp = require('cmp')
          local luasnip = require('luasnip')
          
          cmp.setup({
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            window = {
              completion = cmp.config.window.bordered(),
              documentation = cmp.config.window.bordered(),
            },
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
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' }),
            }),
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
            }, {
              { name = 'buffer' },
              { name = 'path' },
            })
          })
          
          -- Trouble diagnostics
          require('trouble').setup()
          
          -- Todo comments
          require('todo-comments').setup()
          
          -- Terminal
          require('toggleterm').setup({
            size = 20,
            open_mapping = [[<c-\>]],
            direction = 'horizontal',
          })
          
          -- Enhanced keymaps
          local wk = require('which-key')
          wk.add({
            { "<leader>f", group = "Find" },
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
            { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
            
            { "<leader>g", group = "Git" },
            { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" },
            { "<leader>gs", "<cmd>Gitsigns stage_hunk<cr>", desc = "Stage hunk" },
            { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Reset hunk" },
            { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Preview hunk" },
            
            { "<leader>x", group = "Diagnostics" },
            { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Toggle diagnostics" },
            { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
            { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
            { "<leader>xl", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references" },
            
            { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "File explorer" },
            { "<leader>w", "<cmd>w<cr>", desc = "Save file" },
            { "<leader>q", "<cmd>q<cr>", desc = "Quit" },
            { "<leader>/", "<cmd>CommentToggle<cr>", desc = "Toggle comment" },
          })
          
          -- Buffer navigation
          vim.keymap.set('n', '<S-h>', '<cmd>bprevious<cr>', { desc = 'Previous buffer' })
          vim.keymap.set('n', '<S-l>', '<cmd>bnext<cr>', { desc = 'Next buffer' })
          vim.keymap.set('n', '<leader>bd', '<cmd>bdelete<cr>', { desc = 'Delete buffer' })
          
          print("IDE-like Neovim configuration loaded!")
        '';
      };
    };
  };
}
