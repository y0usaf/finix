{
  lib,
  pkgs,
  sources,
  userConfigs,
  hostsDir ? ../../hosts,
}: {
  mkNixosConfigurations = {
    inputs,
    system,
    commonSpecialArgs,
  }: let
    # Configuration
    hostNames = ["y0usaf-desktop"];

    # Import overlays
    overlays = import ../overlays sources;

    # Import host configuration builder
    hostConfigBuilder = import ./host-config.nix {
      inherit lib sources overlays hostsDir userConfigs;
    };
  in
    # Build all host configurations
    builtins.listToAttrs (
      map (hostname:
        hostConfigBuilder.mkHostConfig hostname {
          inherit inputs system commonSpecialArgs pkgs;
        })
      hostNames
    );
}
