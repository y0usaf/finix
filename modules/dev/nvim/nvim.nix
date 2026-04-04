{
  config,
  lib,
  pkgs,
  ...
}: let
  nvim = import ./data/default.nix {inherit lib;};
in {
  config = lib.mkIf config.user.dev.nvim.enable {
    environment.systemPackages = [
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
    ];

    bayt.users."${config.user.name}".files = {
      ".config/nvim/init.lua" = {
        text = nvim.initLua;
      };
    };
  };
}
