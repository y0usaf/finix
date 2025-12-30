{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../../lib/nvim/options.nix
  ];

  config = lib.mkIf config.user.dev.nvim.enable {
    home-manager = {
      users.${config.user.name}.home = {
        # Packages via home-manager
        packages =
          [
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
            pkgs.neovim
            pkgs.lua-language-server
            pkgs.nil
            pkgs.pyright
            pkgs.stylua
            pkgs.alejandra
            pkgs.black
            pkgs.curl
            pkgs.jq
          ]
          ++ lib.optionals config.user.dev.nvim.neovide [pkgs.neovide];

        # Managed configuration files
        file =
          {
            ".config/nvim/init.lua" = {
              text = (import ../../../../lib/nvim {inherit lib;}).initLua;
            };
          }
          // lib.optionalAttrs config.user.dev.nvim.neovide {
            ".config/neovide/config.toml" = {
              text = ''
                [font]
                normal = ["Fast_Mono"]
                size = 14.0
                [window]
                transparency = 0.9
                [input]
                ime = true
              '';
            };
          };
      };
    };
  };
}
