{
  hasSuffix,
  listFilesRecursive,
}: let
  # Only `.nix` files participate in the recursive module graph.
  # Non-module helpers should be imported explicitly.
  expandIfFolder = elem:
    if !builtins.isPath elem || builtins.readFileType elem != "directory"
    then [elem]
    else listFilesRecursive elem;
in
  list:
    builtins.filter
    (elem:
      !builtins.isPath elem
      || hasSuffix ".nix" (toString elem))
    (builtins.concatMap expandIfFolder list)
