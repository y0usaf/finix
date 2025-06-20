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
          
          -- Setup jetpack plugin manager
          local fn = vim.fn
          local jetpack_path = fn.stdpath('data') .. '/site/pack/jetpack/opt/vim-jetpack'
          
          if fn.empty(fn.glob(jetpack_path)) > 0 then
            fn.system({'git', 'clone', 'https://github.com/tani/vim-jetpack.git', jetpack_path})
          end
          
          vim.cmd('packadd vim-jetpack')
          require('jetpack').setup {
            'neovim/nvim-lspconfig',
            'hrsh7th/nvim-cmp',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'L3MON4D3/LuaSnip',
            'saadparwaiz1/cmp_luasnip',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
            'nvim-neo-tree/neo-tree.nvim',
            'MunifTanjim/nui.nvim',
            'lewis6991/gitsigns.nvim',
          }
          
          -- Basic LSP setup
          local lsp = require('lspconfig')
          local capabilities = require('cmp_nvim_lsp').default_capabilities()
          
          lsp.lua_ls.setup{ capabilities = capabilities }
          lsp.nil_ls.setup{ capabilities = capabilities }
          lsp.pyright.setup{ capabilities = capabilities }
          lsp.rust_analyzer.setup{ capabilities = capabilities }
          lsp.tsserver.setup{ capabilities = capabilities }
          
          -- Basic completion
          local cmp = require('cmp')
          cmp.setup({
            snippet = {
              expand = function(args)
                require('luasnip').lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert({
              ['<C-Space>'] = cmp.mapping.complete(),
              ['<CR>'] = cmp.mapping.confirm({ select = true }),
              ['<Tab>'] = cmp.mapping.select_next_item(),
              ['<S-Tab>'] = cmp.mapping.select_prev_item(),
            }),
            sources = {
              { name = 'nvim_lsp' },
              { name = 'luasnip' },
              { name = 'buffer' },
              { name = 'path' },
            }
          })
          
          -- Basic keymaps
          vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
          vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
          vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>')
          
          print("Jetpack configuration loaded!")
        '';
      };
    };
  };
}
