{lib, pkgs, ...}@args: let
  # Import all .nix files in the directory (excluding default.nix) and merge their attributes
  # Usage: (import ../helpers/import-and-merge.nix {inherit lib pkgs;}) ./.;
  importAndMerge = dir: let
    # Get all .nix files in the directory
    files =
      lib.filterAttrs (n: v: v == "regular" && lib.hasSuffix ".nix" n && n != "default.nix")
      (builtins.readDir dir);
    
    # Create paths to each .nix file
    paths = map (name: dir + "/${name}") (builtins.attrNames files);
    
    # Import each file with the given arguments
    imported = map (path: import path args) paths;
    
    # Merge all the imported attributes
    merged = lib.foldl' lib.recursiveUpdate {} imported;
  in
    merged;
in
  importAndMerge