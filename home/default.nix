{lib, ...}: {
  imports =
    (import ../lib/helpers/import-dirs.nix {inherit lib;})
    ./.;
}
