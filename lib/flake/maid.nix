###############################################################################
# Maid Integration Module
# Handles nix-maid integration and home module configuration
###############################################################################
{
  lib,
  pkgs,
  helpers,
  hostsDir ? ../../hosts,
  inputs,
}: let
  shared = import ./shared.nix {inherit lib pkgs helpers hostsDir inputs;};
in {
  # Create NixOS module for maid integration
  mkNixosModule = {
    inputs,
    hostname,
    commonSpecialArgs,
  }: {
    config,
    lib,
    pkgs,
    ...
  }: let
    # Read the host configuration directly
    hostConfig = import (hostsDir + "/${hostname}/default.nix") {inherit pkgs inputs;};
    
    # Extract home configuration from host config
    homeConfig = hostConfig.cfg.home or {};
  in {
    # Import nix-maid module
    imports = [
      inputs.nix-maid.nixosModules.default
    ];
    
    # Apply home configuration to cfg.home
    config = {
      cfg.home = homeConfig;
      
      # Initialize maid for the user
      users.users.y0usaf.maid = {
        packages = [];
      };
    };
  };
}