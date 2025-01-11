# flake.nix
{
  description = "NixOS configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Add Hyprland and hy3 inputs
    hyprland.url = "github:hyprwm/Hyprland";
    hy3 = {
      url = "github:outfoxxed/hy3";
      inputs.hyprland.follows = "hyprland";
    };
  };
  outputs = inputs@{ nixpkgs, home-manager, hyprland, hy3, ... }: {
    nixosConfigurations = {
      "y0usaf-desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; }; # Pass inputs to modules
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.y0usaf = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit inputs; }; # Pass inputs to home-manager
          }
        ];
      };
    };
  };
}
