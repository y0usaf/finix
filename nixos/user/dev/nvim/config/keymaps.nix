{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ((import ../../../../lib/nvim).keymaps);
    };
  };
}
