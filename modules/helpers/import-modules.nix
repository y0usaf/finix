{lib, ...}: let
  # Import all .nix files in the directory, excluding default.nix
  # Usage: imports = (import ../helpers/import-modules.nix {inherit lib;}) ./.;
  
  importModules = dir:
    let
      files =
        lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix")
        (builtins.readDir dir);
        
      paths = map (name: dir + "/${name}") (builtins.attrNames files);
    in
      paths;
in
  importModules