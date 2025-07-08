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
      pkgs.lazygit
      pkgs.ripgrep
      pkgs.fd
      pkgs.tree-sitter
      pkgs.fzf
      pkgs.bat
      pkgs.delta
      pkgs.neovim
      pkgs.gnumake
      pkgs.gcc

      # LSP servers
      pkgs.lua-language-server
      pkgs.nil
      pkgs.pyright
      pkgs.rust-analyzer
      pkgs.typescript-language-server
      pkgs.vscode-langservers-extracted
      pkgs.bash-language-server
      pkgs.marksman
      pkgs.yaml-language-server
      pkgs.dockerfile-language-server-nodejs

      # Formatters
      pkgs.stylua
      pkgs.alejandra
      pkgs.black
      pkgs.prettier
      pkgs.rustfmt

      # Leetcode dependencies
      pkgs.curl
      pkgs.jq
    ];
  };
}
