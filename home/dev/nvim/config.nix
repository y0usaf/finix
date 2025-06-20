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

  # Create MNW-based Neovim package using proper module system
  mnwNeovim = inputs.mnw.lib.wrap pkgs {
    neovim = pkgs.neovim-unwrapped;
    initLua = ''
      vim.g.mapleader = " "
      
      -- Basic LSP setup
      local lsp = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      lsp.lua_ls.setup{ capabilities = capabilities }
      lsp.nil_ls.setup{ capabilities = capabilities }
      lsp.pyright.setup{ capabilities = capabilities }
      lsp.rust_analyzer.setup{ capabilities = capabilities }
      lsp.ts_ls.setup{ capabilities = capabilities }
      
      -- Basic completion
      local cmp = require('cmp')
      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'buffer' },
        }
      })
      
      -- Basic telescope keymaps
      vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
      vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
      
      print("MNW configuration loaded successfully!")
    '';
    
    plugins = {
      start = with pkgs.vimPlugins; [
        # Core functionality
        nvim-lspconfig nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path cmp_luasnip luasnip
        nvim-treesitter.withAllGrammars plenary-nvim nvim-web-devicons lualine-nvim
        indent-blankline-nvim which-key-nvim telescope-nvim telescope-fzf-native-nvim
        neo-tree-nvim bufferline-nvim nui-nvim gitsigns-nvim lazygit-nvim comment-nvim
        nvim-autopairs mini-indentscope conform-nvim trouble-nvim toggleterm-nvim persistence-nvim
        
        # ADHD-friendly enhancements
        alpha-nvim nvim-notify noice-nvim dressing-nvim nvim-colorizer-lua
        zen-mode-nvim twilight-nvim neoscroll-nvim rainbow-delimiters-nvim
        fidget-nvim vim-illuminate todo-comments-nvim nvim-hlslens
      ];
    };
    
    extraBinPath = lspPackages;
  };
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [
        pkgs.lazygit pkgs.ripgrep pkgs.fd pkgs.tree-sitter pkgs.fzf pkgs.bat pkgs.delta mnwNeovim
      ];

      # Note: mnw handles all Lua configuration through its module system
      # No manual file.xdg_config needed when using mnw.lib.wrap properly
    };
  };
}
