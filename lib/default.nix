let
  sources = import ../npins;
  system = "x86_64-linux";

  # Centralized nixpkgs config
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

  inherit (pkgs) lib;

  # Custom generators library
  genLib = import ./generators lib;

  # Host configs
  hostConfigs = {
    y0usaf-desktop = import ../configs/hosts/y0usaf-desktop {inherit pkgs lib;};
    y0usaf-laptop = import ../configs/hosts/y0usaf-laptop {inherit pkgs lib;};
  };
in {
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
          # Hjem
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
          inherit hostConfig sources lib genLib;
          inherit (sources) disko;
        };
      };
    })
  hostConfigs;
}
