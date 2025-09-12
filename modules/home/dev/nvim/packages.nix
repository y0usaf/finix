{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
in {
  config = lib.mkIf cfg.enable {
    usr.packages = [
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
      pkgs.neovim-unwrapped # Use nixpkgs version for npins compatibility
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
