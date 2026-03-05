{
  lib,
  pkgs,
}: {
  inherit ((import ./toHyprconf.nix lib)) toHyprconf;
  inherit ((import ./toNiriconf.nix lib)) toNiriconf;
  inherit ((import ./toKDL.nix {inherit lib;})) toKDL;
  inherit ((import ./toTOML.nix {inherit lib pkgs;})) toTOML;
}
