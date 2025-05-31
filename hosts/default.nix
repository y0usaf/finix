###############################################################################
# Host Configuration Loader - Minimalist Meta Import
# Only imports system modules, configuration is applied via system.nix
###############################################################################
{
  imports = [
    ../system
  ];
}
