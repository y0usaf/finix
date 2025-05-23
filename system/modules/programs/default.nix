###############################################################################
# Programs Configuration Module
# User-facing applications and environment configuration
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}
