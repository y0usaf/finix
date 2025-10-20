{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    environment.systemPackages = [
      pkgs.ripgrep
      pkgs.fd
      pkgs.tree-sitter
      (pkgs.tree-sitter.withPlugins (p:
        with p; [
          tree-sitter-nix
          tree-sitter-lua
          tree-sitter-python
          tree-sitter-markdown
          tree-sitter-json
        ]))
      # Neovim with plugins
      (pkgs.neovim.override {
        configure = {
          packages.myNeovimPackage = with pkgs.vimPlugins; {
            start = [
              # Core dependencies
              plenary-nvim
              nvim-web-devicons
              nui-nvim

              # File navigation
              neo-tree-nvim

              # Telescope
              telescope-nvim
              telescope-fzf-native-nvim

              # LSP and Completion
              nvim-lspconfig
              nvim-cmp
              cmp-nvim-lsp
              cmp-buffer
              cmp-path
              luasnip
              cmp_luasnip
              lspkind-nvim
              lsp_lines-nvim

              # Treesitter
              nvim-treesitter
              nvim-treesitter-textobjects

              # Utilities
              comment-nvim
              nvim-autopairs
              nvim-ufo
              promise-async
              fidget-nvim
              vim-illuminate
              twilight-nvim
              toggleterm-nvim

              # Theme & UI
              cyberdream-nvim
              dropbar-nvim
              dressing-nvim
              windows-nvim
              lualine-nvim
              gitsigns-nvim
              indent-blankline-nvim
              flash-nvim
              mini-nvim

              # Specialized
              wilder-nvim
            ];
          };
        };
      })
      pkgs.lua-language-server
      pkgs.nil
      pkgs.pyright
      pkgs.stylua
      pkgs.alejandra
      pkgs.black
      pkgs.curl
      pkgs.jq
    ];
  };
}
