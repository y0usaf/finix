{
  inputs,
  system,
  nixpkgsConfig,
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = [
      inputs.neovim-nightly-overlay.overlays.default
      (_final: _prev: {
        niri = inputs.niri.packages.${system}.default;
      })
    ];
  };

  inherit (pkgs) lib;

  genLib = import ../../lib/generators lib;
in {
  nixosConfigurations =
    lib.mapAttrs (_hostName: hostConfig:
      import (inputs.nixpkgs + "/nixos") {
        inherit system;
        configuration = {
          imports = [
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
                  overlays = [
                    inputs.neovim-nightly-overlay.overlays.default
                    (_final: _prev: {
                      niri = inputs.niri.packages.${system}.default;
                    })
                  ];
                };
              })
            (inputs.disko + "/module.nix")
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
            inputs.nvf.nixosModules.default
            inputs.mango.nixosModules.mango
            ../user
          ];
          _module.args = {
            inherit hostConfig lib genLib system;
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
