{
  config,
  lib,
  ...
}: let
  nvim = import ./data/default.nix {inherit lib;};
in {
  config = lib.mkIf config.user.dev.nvim.enable {
    bayt.users."${config.user.name}".files.".config/nvim/init.lua" = {
      text = nvim.initLua;
    };
  };
}
