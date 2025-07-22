{lib, ...}:
let
  importDirs = dir: let
    dirs = lib.filterAttrs (n: v: v == "directory" && n != ".git") (builtins.readDir dir);
    dirPaths = lib.mapAttrsToList (name: _: dir + "/${name}/default.nix") dirs;
  in
    lib.filter (path: builtins.pathExists path) dirPaths;
in {
  imports = importDirs ./.;
}
