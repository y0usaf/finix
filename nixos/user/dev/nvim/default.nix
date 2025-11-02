{
  config,
  lib,
  ...
}: let
  nvim = import ../../../../lib/nvim {inherit lib;};
in {
  imports = [
    ../../../../lib/nvim/options.nix
    nvim.packages
    nvim.neovide
  ];

  config = lib.mkIf config.user.dev.nvim.enable {
    usr.files.".config/nvim/init.lua" = {
      text = nvim.initLua;
    };
  };
}
