# Neovim packages module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.packages = [
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

      # LSP servers (minimal essential set)
      pkgs.lua-language-server
      pkgs.nil
      pkgs.pyright

      # Formatters (essential only)
      pkgs.stylua
      pkgs.alejandra
      pkgs.black

      # Leetcode dependencies
      pkgs.curl
      pkgs.jq
    ];
  };
}
