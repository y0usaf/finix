{lib, ...}: let
  importModules = dir: let
    files = lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix") (builtins.readDir dir);
  in
    map (name: dir + "/${name}") (builtins.attrNames files);
in {
  imports = importModules ./.;
}
