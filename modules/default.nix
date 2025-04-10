{lib, ...}: {
  # Import all module directories that contain a default.nix
  imports = (import ./helpers/import-dirs.nix {inherit lib;}) ./.;
}