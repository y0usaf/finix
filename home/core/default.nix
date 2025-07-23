{lib, ...}: let
  importModules = dir: let
    files = lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix") (builtins.readDir dir);
  in
    map (name: dir + "/${name}") (builtins.attrNames files);
  importDirs = dir: let
    dirs = lib.filterAttrs (n: v: v == "directory" && n != ".git") (builtins.readDir dir);
    dirPaths = lib.mapAttrsToList (name: _: dir + "/${name}/default.nix") dirs;
  in
    lib.filter (path: builtins.pathExists path) dirPaths;
in {
  imports =
    (importModules ./.)
    ++ (importDirs ./.)
    ++ [
      ./fonts
    ];
}
