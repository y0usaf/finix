{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  opencodeCfg = config.home.dev.opencode;
  username = config.user.name;
in {
  imports = [
    ./neovide.nix
    ./options.nix
    ./packages.nix
  ];

  config = lib.mkIf cfg.enable {
    hjem.users.${username}.files = {
      # Core nvim configuration
      ".config/nvim/init.lua".source = ./config/init.lua;
      ".config/nvim/lua/vim-pack-config.lua".source = ./config/lua/vim-pack-config.lua;

      # Conditional opencode files - only if opencode is enabled
      ".config/nvim/lua/vim-pack-opencode.lua" = lib.mkIf opencodeCfg.enable {
        source = ./config/lua/vim-pack-opencode.lua;
      };
      ".config/nvim/lua/opencode-config.lua" = lib.mkIf opencodeCfg.enable {
        source = ./config/lua/opencode-config.lua;
      };
    };
  };
}
