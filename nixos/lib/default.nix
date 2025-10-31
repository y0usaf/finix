{
  inputs,
  system,
  nixpkgsConfig,
  claudeCodeLib,
}: let
  # Direct pkgs with neovim-nightly overlay
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = [inputs.neovim-nightly-overlay.overlays.default];
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
              (removeAttrs hostConfig ["imports" "homeDirectory" "trustedUsers"])
              // {
                inherit (hostConfig) imports;
                user = {
                  name = builtins.head hostConfig.trustedUsers;
                  inherit (hostConfig) homeDirectory;
                };
                nixpkgs = {
                  config = nixpkgsConfig;
                  overlays = [inputs.neovim-nightly-overlay.overlays.default];
                };
                # Assertions
                assertions = [
                  {
                    assertion = hostConfig.trustedUsers != [] && builtins.isList hostConfig.trustedUsers;
                    message = "Host configuration must define trustedUsers as a non-empty list. The first user will be used as the primary system user.";
                  }
                ];
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
            ../user
          ];
          _module.args = {
            inherit hostConfig lib genLib system claudeCodeLib;
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
