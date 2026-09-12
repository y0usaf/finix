{
  config,
  lib,
  inputs,
  system,
  ...
}: let
  cfg = config.finix;
  tools =
    (lib.evalModules {
      specialArgs = {
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        flakeInputs = inputs;
      };
      modules = [
        ./shell/ekko/package.nix

        ./shell/ekko/preview-zellij
        ./dev/work/vercel/wrapper.nix
        ./dev/ai/hermes/project-runner.nix
      ];
    }).config.user;
  ekko = tools.shell.ekko.package;
  preview = tools.shell.ekko.zellijPreview;
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
        ekko-preview = ekko;
        ekko-zellij-preview = preview.package;
        ekko-zellij-runtime = preview.runtime;
        hermes-project = tools.dev.ai.hermes.projectRunner;
        p4g-setup = cfg.hosts.y0usaf-desktop.config.user.gaming.p4g.package;
        tomoe = inputs.tomoe.packages.${system}.default;
      };

    apps.${system}.ekko-zellij-preview = {
      type = "app";
      meta.description = "Disposable selectable Lisp Zellij profile preview";
      program = "${preview.package}/bin/finix-ekko-zellij-preview";
    };

    # Verification remains an actual full-system build, not script fixtures.
    checks."${system}".y0usaf-desktop = cfg.hosts.y0usaf-desktop.config.system.build.toplevel;

    formatter."${system}" = inputs.nixpkgs.legacyPackages."${system}".alejandra;
  };
}
