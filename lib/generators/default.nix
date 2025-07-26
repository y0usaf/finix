{lib}: let
  hyprconf = import ./toHyprconf.nix lib;
  kdl = import ./toKdl.nix lib;
in
  # Flatten the generators to top level
  hyprconf // kdl
