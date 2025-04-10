{lib, ...}: let
  # Import all directories that contain a default.nix file
  # Usage: imports = (import ../helpers/import-dirs.nix {inherit lib;}) ./.;
  importDirs = dir: let
    # Get all directories in the current directory
    dirs =
      lib.filterAttrs (n: v: v == "directory" && n != ".git")
      (builtins.readDir dir);

    # Create paths to each default.nix file in the directories
    dirPaths = lib.mapAttrsToList (name: _: dir + "/${name}/default.nix") dirs;

    # Filter out directories that don't have a default.nix file
    validPaths = lib.filter (path: builtins.pathExists path) dirPaths;
  in
    validPaths;
in
  importDirs
