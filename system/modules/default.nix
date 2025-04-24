{lib, ...}: {
  imports = 
    # Import all modules in the current directory
    (import ../../lib/helpers/import-modules.nix {inherit lib;}) ./. ++
    # Recursively import all subdirectories with default.nix
    (import ../../lib/helpers/import-dirs.nix {inherit lib;}) ./.;
}