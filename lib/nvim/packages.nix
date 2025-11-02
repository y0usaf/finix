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
  };
}
