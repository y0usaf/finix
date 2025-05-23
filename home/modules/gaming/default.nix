###############################################################################
# Gaming Module
# Master import file for all gaming-related modules
###############################################################################
{lib, ...}: {
  imports =
    (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.
    ++ (import ../../../lib/helpers/import-dirs.nix {inherit lib;}) ./.;
}
