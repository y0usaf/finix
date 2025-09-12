lib: 
let
  niriModule = import ./toNiriconf.nix lib;
  kdlModule = import ./toKDL.nix {inherit lib;};
in {
  toHyprconf = import ./toHyprconf.nix lib;
  inherit (niriModule) toNiriconf;
  inherit (kdlModule) toKDL;
}
