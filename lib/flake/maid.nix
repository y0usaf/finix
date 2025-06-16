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
}: {
  # Create NixOS module for maid integration
  mkNixosModule = {
    inputs,
    hostname,
    commonSpecialArgs,
  }: {
    config,
    pkgs,
    ...
  }: let
    # Read the host configuration directly
    hostConfig = import (hostsDir + "/${hostname}/default.nix") {inherit pkgs inputs;};

    # Extract home configuration from host config
    homeConfig = hostConfig.home or {};
  in {
    # Import nix-maid module
    imports = [
      inputs.nix-maid.nixosModules.default
    ];

    # Apply home configuration directly
    config = {
      home = homeConfig;

      # Initialize maid for the user
      users.users.y0usaf.maid = {
        packages = [];
      };
    };
  };
}
