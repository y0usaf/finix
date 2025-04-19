{lib, ...}: {
  # Import all module directories that contain a default.nix
  imports = (import ../../lib/helpers/import-dirs.nix {inherit lib;}) ./.;
}
