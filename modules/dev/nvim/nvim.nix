{
  config,
  lib,
  pkgs,
  ...
}: let
  nvim = import ./data/default.nix {inherit lib;};
in {
  config = lib.mkIf config.user.dev.nvim.enable {
    environment.systemPackages =
      [
        pkgs.ripgrep
        pkgs.fd
        pkgs.tree-sitter
        (pkgs.tree-sitter.withPlugins (p: [
          p.tree-sitter-nix
          p.tree-sitter-lua
          p.tree-sitter-python
          p.tree-sitter-markdown
          p.tree-sitter-json
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
      ++ lib.optionals config.user.dev.nvim.neovide [
        pkgs.neovide
      ];

    bayt.users."${config.user.name}".files =
      {
        ".config/nvim/init.lua" = {
          text = nvim.initLua;
        };
      }
      // lib.optionalAttrs config.user.dev.nvim.neovide {
        ".config/neovide/config.toml" = {
          clobber = true;
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
}
