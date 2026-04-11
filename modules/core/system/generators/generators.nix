{
  lib,
  pkgs,
  ...
}: {
  config.lib.generators = {
    inherit ((import ./toHyprconf.nixlib lib)) toHyprconf;
    inherit ((import ./toNiriconf.nixlib lib)) toNiriconf;
    inherit ((import ./toKDL.nixlib {inherit lib;})) toKDL;
    inherit ((import ./toTOML.nixlib {inherit lib pkgs;})) toTOML;
  };
}
