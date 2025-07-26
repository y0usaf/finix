{ lib }: {
  hyprconf = import ./toHyprconf.nix lib;
  kdl = import ./toKdl.nix lib;
}