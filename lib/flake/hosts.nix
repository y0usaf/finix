{
  lib,
  pkgs,
  hostsDir ? ../../system/hosts,
  homeHostsDir ? ../../home/hosts,
}: let
  # Import system and home modules
  systemModule = import ./system-module.nix {inherit lib pkgs hostsDir homeHostsDir;};
  homeModule = import ./home-module.nix {inherit lib pkgs hostsDir homeHostsDir;};
in {
  # Re-export common attributes
  inherit (systemModule) hostNames systemConfigs;
  inherit (homeModule) homeConfigs;

  # Re-export system-specific functions
  inherit (systemModule) mkNixosConfigurations;

  # Re-export home-specific functions
  inherit (homeModule) mkHomeConfigurations;
}
