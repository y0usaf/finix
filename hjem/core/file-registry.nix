#===============================================================================
# File Registry Core Module
# Enables the universal file registry system
#===============================================================================
{
  config,
  lib,
  ...
}: let
  registry = import ../../lib/helpers/file-registry.nix {inherit lib;};
in {
  #===========================================================================
  # Enable File Registry Options
  #===========================================================================
  options = registry.mkFileRegistryOptions;
  
  #===========================================================================
  # Auto-build All Registered Files
  #===========================================================================
  config = registry.buildRegisteredFiles {
    declarations = config.fileRegistry.declare;
    content = config.fileRegistry.content;
    early = config.fileRegistry.early;
    late = config.fileRegistry.late;
    username = config.cfg.shared.username;
  };
}