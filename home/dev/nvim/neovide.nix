# Simple Neovide package installation
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  username = "y0usaf";
in {
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    users.users.${username}.maid = {
      packages = with pkgs; [
        neovide
      ];

      file.xdg_config."neovide/config.toml".text = ''
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
