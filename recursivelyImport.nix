{lib}: let
  # Only `.nix` files participate in the recursive module graph.
  # Non-module helpers should be imported explicitly.
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
