{lib}: let
  # Only `.nix` files participate in the recursive module graph.
  # Helper expressions should use a non-`.nix` extension such as `.nixlib`.
  expandIfFolder = elem:
    if !builtins.isPath elem || builtins.readFileType elem != "directory"
    then [elem]
    else
      builtins.filter
      (f: !(lib.hasInfix "/npins/" (toString f)))
      (lib.filesystem.listFilesRecursive elem);
in
  list:
    builtins.filter
    (elem: !builtins.isPath elem || lib.hasSuffix ".nix" (toString elem))
    (builtins.concatMap expandIfFolder list)
