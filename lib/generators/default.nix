lib: {
  toHyprconf = import ./toHyprconf.nix lib;
  inherit ((import ./toNiriconf.nix lib)) toNiriconf;
  inherit ((import ./toKDL.nix {inherit lib;})) toKDL;
}
