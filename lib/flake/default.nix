# Re-export the contents of system.nix and home.nix
{
  lib,
  pkgs,
  ...
}: {
  # System-related functions
  inherit
    (import ./system.nix {inherit lib pkgs;})
    hostNames
    systemConfigs
    mkNixosConfigurations
    ;

  # Home-related functions
  inherit
    (import ./home.nix {inherit lib pkgs;})
    homeConfigs
    mkHomeConfigurations
    ;
}
