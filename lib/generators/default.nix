{lib}: let
  hyprconf = import ./toHyprconf.nix lib;
in
  hyprconf
