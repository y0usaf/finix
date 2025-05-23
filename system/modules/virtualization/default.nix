###############################################################################
# Virtualization Configuration Module
# Container and VM solutions:
# - LXD
# - Waydroid
# - Docker
# - Podman
###############################################################################
{lib, ...}: {
  imports = (import ../../../lib/helpers/import-modules.nix {inherit lib;}) ./.;
}
