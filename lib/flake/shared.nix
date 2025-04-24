{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  # Get all valid host names (excluding special directories and files)
  hostNames = builtins.filter (
    name:
      name
      != "README.md"
      && name != "default.nix"
      && builtins.pathExists (hostsDir + "/${name}/default.nix")
      && builtins.pathExists (homeHostsDir + "/${name}/default.nix")
  ) (builtins.attrNames (builtins.readDir hostsDir));

  # Import system configurations for each host
  systemConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (hostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );

  # Import home configurations for each host
  homeConfigs = builtins.listToAttrs (
    map
    (name: {
      inherit name;
      value = import (homeHostsDir + "/${name}/default.nix") {inherit lib pkgs;};
    })
    hostNames
  );
in {
  inherit hostNames systemConfigs homeConfigs;
}
