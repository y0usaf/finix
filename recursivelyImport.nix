{
  hasSuffix,
  listFilesRecursive,
}: let
  isPath = elem: builtins.isPath elem;

  # Only `.nix` files participate in the recursive module graph.
  # Non-module helpers should be imported explicitly.
  expandIfFolder = elem:
    if !isPath elem || builtins.readFileType elem != "directory"
    then [elem]
    else listFilesRecursive elem;
in
  list:
    builtins.filter
    (elem:
      !isPath elem
      || hasSuffix ".nix" (toString elem))
    (builtins.concatMap expandIfFolder list)
