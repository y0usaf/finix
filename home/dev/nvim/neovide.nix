# Simple Neovide package installation
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf (cfg.enable && cfg.neovide) {
    users.users.${username}.maid.packages = with pkgs; [
      neovide
    ];
  };
}
