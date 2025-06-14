# MAID INTEGRATION UTILITIES
# Provides complete nix-maid integration for NixOS configurations
{
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
in {
  # Create a complete NixOS module for maid integration
  mkNixosModule = {
    inputs,
    hostname,
    commonSpecialArgs,
    ...
  }: {
    config,
    pkgs,
    ...
  }: let
    # Hardcode username for now - will be configurable later
    username = "y0usaf";
  in {
    # Import nix-maid module
    imports = [inputs.nix-maid.nixosModules.default];

    # Create md alias for cleaner access to maid configuration
    options.md = mkOption {
      type = types.attrs;
      default = {};
      description = "Alias for users.users.${username}.maid configuration";
    };

    config = {
      # Forward md configuration to actual maid config
      users.users.${username}.maid = config.md;
    };
  };
}