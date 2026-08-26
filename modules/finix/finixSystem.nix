# Shared Finix package policy and system builder.
# Host composition lives in default.nix; boot and deployment drivers are kept
# in this directory and host-specific policy lives under hosts/.
{
  inputs,
  system,
}: let
  mkPkgs = cudaSupport:
    import (toString inputs.nixpkgs) {
      inherit system;
      config = {
        allowUnfree = true;
        inherit cudaSupport;
      };
      overlays = [
        inputs.claude-code-nix.overlays.default
        (final: prev: {
          rush = inputs.rush.packages.${system}.default;
        })
        (_: prev: let
          prevObsPlugins = prev.obs-studio-plugins;
        in {
          obs-studio-plugins = prevObsPlugins // {
            obs-vertical-canvas = prevObsPlugins.obs-vertical-canvas.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
              '';
            });
          };
        })
      ];
    };
  basePkgs = mkPkgs false;
  cudaPkgs = mkPkgs true;
  inherit (basePkgs) lib;

  mkFinixSystem = {modules, cudaSupport ? false}:
    let
      pkgs = if cudaSupport then cudaPkgs else basePkgs;
    in inputs.finix.lib.finixSystem {
      inherit lib;
      specialArgs = {
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
        flakeInputs = inputs;
      };
      modules = [
        {nixpkgs.pkgs = lib.mkDefault pkgs;}
        {
          options.lib = lib.mkOption {
            type = lib.types.submodule {freeformType = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);};
            default = {};
          };
        }
        {
          options = {
            boot.loader.limine.secureBoot.enable = lib.mkEnableOption "";
            hardware.bluetooth.enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            nix.settings.max-jobs = lib.mkOption {
              type = lib.types.str;
              default = "auto";
            };
          };
        }
        inputs.finix.nixosModules.bash
        inputs.finix.nixosModules.dhcpcd
        inputs.finix.nixosModules.getty
        inputs.finix.nixosModules.openssh
        ./sudo
        inputs.finix.nixosModules.sysklogd
        ./common.nix
        ./persistence/bind-replay.nix
        ./persistence/home-reset.nix
        ./persistence/identity.nix
      ] ++ modules;
    };
in {
  inherit lib basePkgs cudaPkgs mkFinixSystem;
}
