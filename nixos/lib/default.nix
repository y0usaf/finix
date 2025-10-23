{
  inputs,
  system,
  nixpkgsConfig,
}: let
  # Direct pkgs without overlays
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
  };

  inherit (pkgs) lib;

  # Custom generators library
  genLib = import ../../lib/generators lib;
in {
  nixosConfigurations =
    lib.mapAttrs (_hostName: hostConfig:
      import (inputs.nixpkgs + "/nixos") {
        inherit system;
        configuration = {
          imports = [
            # Host system configuration
            (_:
              (removeAttrs hostConfig ["imports" "homeDirectory"])
              // {
                inherit (hostConfig) imports;
                user = {
                  name = "y0usaf";
                  inherit (hostConfig) homeDirectory;
                };
                nixpkgs = {
                  config = nixpkgsConfig;
                };
              })
            # Disko
            (inputs.disko + "/module.nix")
            # Hjem
            ({...}: {
              imports = [
                (_: {
                  _module.args.hjem-lib = import (inputs.hjem + "/lib.nix") {inherit lib pkgs;};
                })
                (inputs.hjem + "/modules/nixos")
              ];
              config.hjem = {
                linker = pkgs.callPackage (inputs.smfh + "/package.nix") {};
                users = {};
              };
            })
            # nvf module for neovim
            inputs.nvf.nixosModules.default
            ../user/options.nix
            ../user
          ];
          _module.args = {
            inherit hostConfig lib genLib system;
            # Pass inputs for modules that might need them
            flakeInputs = inputs;
          };
        };
      })
    {
      y0usaf-desktop = import ../../configs/hosts/y0usaf-desktop {
        inherit pkgs lib system inputs;
        flakeInputs = inputs;
      };
      y0usaf-laptop = import ../../configs/hosts/y0usaf-laptop {
        inherit pkgs lib system inputs;
        flakeInputs = inputs;
      };
      y0usaf-server = import ../../configs/hosts/y0usaf-server {
        inherit pkgs lib system inputs;
        flakeInputs = inputs;
      };
    };
}
