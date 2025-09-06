{...}: {
  imports = [
    ./cachix.nix
    ./lix.nix
    ./nix-cache.nix
    ./nix-ld.nix
    ./nix-package-management.nix
    ./nix-tools.nix
    ./system.nix
    ./xdg-portal.nix
  ];
}
