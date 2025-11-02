{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = let
        nvimLib = import ../../../../lib/nvim;
        pluginsStr =
          lib.concatStringsSep ",\n    " (map (url: "\"${url}\"") nvimLib.plugins);
      in ''
        -- Leader keys
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        -- Load plugins
        vim.pack.add({
          ${pluginsStr}
        })

        ${nvimLib.settings}
      '';
    };
  };
}
