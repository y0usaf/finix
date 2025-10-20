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
    programs.nvf = {
      enable = true;
      defaultEditor = true;

      settings = {
        vim = {
          viAlias = true;
          vimAlias = true;

          # LSP
          lsp = {
            enable = true;
            formatOnSave = true;
            lightbulb.enable = true;
            trouble.enable = true;
            lspSignature.enable = true;
          };

          # Languages
          languages = {
            enableFormat = true;
            enableTreesitter = true;
            enableExtraDiagnostics = true;
            nix.enable = true;
            lua.enable = true;
            python.enable = true;
            markdown.enable = true;
          };

          # UI/Visuals
          visuals = {
            nvim-web-devicons.enable = true;
            nvim-cursorline.enable = true;
            fidget-nvim.enable = true;
            indent-blankline.enable = true;
          };

          # Theme
          theme = {
            enable = true;
            name = "catppuccin";
            style = "mocha";
            transparent = true;
          };

          # Statusline
          statusline.lualine = {
            enable = true;
            theme = "catppuccin";
          };

          # Autopairs
          autopairs.nvim-autopairs.enable = true;

          # Completion
          autocomplete.nvim-cmp.enable = true;
          snippets.luasnip.enable = true;

          # File tree
          filetree.neo-tree.enable = true;

          # Tabline
          tabline.nvimBufferline.enable = true;

          # Telescope
          telescope.enable = true;

          # Git
          git = {
            enable = true;
            gitsigns.enable = true;
          };
        };
      };
    };
  };
}
