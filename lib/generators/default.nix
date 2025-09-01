{lib}: let
  hyprconf = import ./toHyprconf.nix lib;
  kdl = import ./toKDL.nix {inherit lib;};
  niriconf = import ./toNiriconf.nix lib;
  lua = import ./toLua.nix lib;
  ini = import ./toINI.nix {inherit lib;};
  shell = import ./toShell.nix {inherit lib;};
in
  hyprconf // kdl // niriconf // lua // ini // shell
