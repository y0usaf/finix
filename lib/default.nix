let
  sources = import ../npins;
  system = "x86_64-linux";

  # Shared nixpkgs config
  nixpkgsConfig = {
    allowUnfree = true;
    cudaSupport = true;
    permittedInsecurePackages = [
      "qtwebengine-5.15.19"
    ];
  };

  # Direct overlays import
  overlays = import ./overlays sources;

  # Direct pkgs with overlays
  pkgs = import sources.nixpkgs {
    inherit system overlays;
    config = nixpkgsConfig;
  };

  # Simple lib extension with custom generators
  lib = pkgs.lib.extend (final: prev: {
    generators = prev.generators // (import ./generators final);
  });

  # Host configs
  hostConfigs = {
    y0usaf-desktop = import ../configs/hosts/y0usaf-desktop {inherit pkgs lib;};
    y0usaf-laptop = import ../configs/hosts/y0usaf-laptop {inherit pkgs lib;};
  };
in {
  inherit lib;
  formatter.${system} = pkgs.alejandra;

  nixosConfigurations = lib.mapAttrs (_hostName: hostConfig:
    import (sources.nixpkgs + "/nixos") {
      inherit system;
      configuration = {
        imports = [
          # Host system configuration
          (_: {
            inherit (hostConfig) imports;
            user = {
              name = "y0usaf";
              inherit (hostConfig) homeDirectory;
            };
            nixpkgs = {
              inherit overlays;
              config = nixpkgsConfig;
            };
          })
          # Hjem with extended lib
          ({...}: {
            imports = [
              (_: {
                _module.args.hjem-lib = import (sources.hjem + "/lib.nix") {inherit lib pkgs;};
              })
              (sources.hjem + "/modules/nixos")
            ];
            config.hjem = {
              linker = pkgs.callPackage (sources.smfh + "/package.nix") {};
              users = {};
            };
          })
          ./user-config.nix
          ../modules/home
        ];
        _module.args = {
          inherit hostConfig sources lib;
          inherit (sources) disko nix-minecraft Fast-Fonts;
          # Pass generators directly to bypass lib scoping issues
          generators = lib.generators;
        };
      };
    })
  hostConfigs;
}
