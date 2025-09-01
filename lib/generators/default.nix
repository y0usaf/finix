{lib}: let
  hyprconf = import ./toHyprconf.nix lib;
  lua = import ./toLua.nix lib;
in
  hyprconf // lua
