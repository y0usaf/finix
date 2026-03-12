{
  inputs,
  system,
  nixpkgsConfig,
}: let
  commonOverlays = [
    inputs.neovim-nightly-overlay.overlays.default
    inputs.claude-code-nix.overlays.default
    inputs.gpui-shell.overlays.default
    # Fix obs-vertical-canvas Qt6GuiPrivate cmake detection
    (_: prev: {
      obs-studio-plugins =
        prev.obs-studio-plugins
        // {
          obs-vertical-canvas = prev.obs-studio-plugins.obs-vertical-canvas.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                # Add find_package for Qt6 GuiPrivate component
                sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
              '';
          });
        };
    })
  ];

  pkgs = import inputs.nixpkgs {
    inherit system;
    config = nixpkgsConfig;
    overlays = commonOverlays;
  };

  inherit (pkgs) lib;
in {
  nixosConfigurations =
    lib.mapAttrs (_: hostConfig:
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
            inputs.tweakcc.nixosModules.default
            inputs.mango.nixosModules.mango
            inputs.impermanence.nixosModules.impermanence
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
            inherit hostConfig lib;
            genLib = import ../../lib/generators {inherit lib pkgs;};
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
      y0usaf-framework = import ../../configs/hosts/y0usaf-framework {
        inherit pkgs lib system inputs;
        flakeInputs = inputs;
      };
      y0usaf-server = import ../../configs/hosts/y0usaf-server {
        inherit pkgs lib system inputs;
        flakeInputs = inputs;
      };
    };
}
