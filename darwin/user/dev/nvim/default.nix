{
  config,
  lib,
  pkgs,
  ...
}: let
  nvim = import ../../../lib/nvim {inherit lib;};
in {
  imports = [
    ../../../lib/nvim/options.nix
  ];

  config = lib.mkIf config.user.dev.nvim.enable {
    # Packages via home-manager
    home-manager.users.${config.user.name}.home.packages =
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

    # Init.lua file
    home-manager.users.${config.user.name}.home.file.".config/nvim/init.lua" = {
      text = nvim.initLua;
    };

    # Neovide config file
    home-manager.users.${config.user.name}.home.file.".config/neovide/config.toml" = lib.mkIf config.user.dev.nvim.neovide {
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
}
