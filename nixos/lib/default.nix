{
  inputs,
  system,
  nixpkgsConfig,
}: let
  commonOverlays = [
    inputs.neovim-nightly-overlay.overlays.default
    (_final: _prev: {
      niri = inputs.niri.packages.${system}.default;
    })
  ];

  pkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = commonOverlays;
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
            (lib.removeAttrs hostConfig ["homeDirectory"])
            (inputs.disko + "/module.nix")
            ({...}: {
              imports = [
                (import (inputs.hjem + "/modules/nixos")).hjem
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
          nixpkgs = {
            config = nixpkgsConfig;
            overlays = commonOverlays;
          };
          user = {
            name = "y0usaf";
            inherit (hostConfig) homeDirectory;
          };
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
