{
  config,
  lib,
  inputs,
  system,
  ...
}: let
  cfg = config.finix;
in {
  imports = [./finix];
  options.flake = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    description = "Public flake outputs assembled from evaluated modules.";
  };
  config.flake = {
    nixosConfigurations =
      cfg.hosts
      // {
        # Finix is the installed server system; retain the hostname alias for
        # tools that only inspect nixosConfigurations.
        y0usaf-server-finix = cfg.hosts.y0usaf-server;
      };

    nixOnDroidConfigurations = {
      default = inputs."nix-on-droid".lib.nixOnDroidConfiguration {
        pkgs = import (toString inputs.nixpkgs) {
          system = "aarch64-linux";
        };
        extraSpecialArgs = {
          flakeInputs = inputs;
        };
        modules = [
          ./hosts/android-phone/nix-on-droid.nix
        ];
      };
    };

    finixConfigurations = cfg.hosts;

    packages."${system}" =
      cfg.packages
      // {
        p4g-setup = cfg.hosts.y0usaf-desktop.config.user.gaming.p4g.package;
        tomoe = inputs.tomoe.packages.${system}.default;
      };

    # Verification remains an actual full-system build, not script fixtures.
    checks."${system}".y0usaf-desktop = cfg.hosts.y0usaf-desktop.config.system.build.toplevel;

    formatter."${system}" = inputs.nixpkgs.legacyPackages."${system}".alejandra;
  };
}
