{
  inputs,
  system,
  config,
  ...
}: let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  recursivelyImport = import ../../recursivelyImport.nix {inherit lib;};
  graphicalRoots = [
    ../core
    ../desktop
    ../dev
    ../gaming
    ../shell
    ../tools
    ../user-services
    ../hosts/common
  ];
  commonGraphicalModules = recursivelyImport graphicalRoots;
  hostGraphicalModules = hostDir: recursivelyImport [hostDir];
  desktopModules = commonGraphicalModules ++ hostGraphicalModules ../hosts/y0usaf-desktop;
  frameworkModules = commonGraphicalModules ++ hostGraphicalModules ../hosts/y0usaf-framework;

  pkgs = config.finix.basePkgs;
  mkFinixSystem = config.finix.mkSystem;

  serverPersistent = mkFinixSystem {
    modules =
      [
        inputs.finix.nixosModules.cron
        inputs.finix.nixosModules.nftables
        inputs.finix.nixosModules.postgresql
        inputs.finix.nixosModules.nix-daemon
      ]
      ++ [
        ../hosts/y0usaf-server/finix/services.nix
        ../hosts/y0usaf-server/finix/persistent.nix
        ../hosts/y0usaf-server/finix/attic.nix
        ../hosts/y0usaf-server/finix/shell.nix
        ../hosts/y0usaf-server/finix/paseo.nix
        inputs.manzil.finixModules.default
        ../hosts/common/finix-base.nix
        ../hosts/common/finix-btrfs.nix
        ../hosts/common/finix-identity.nix
        ../hosts/common/finix-nix-daemon.nix
        ../hosts/common/manzil.nix
        ../hosts/common/ssh-keys.nix
        ../core/user/user-config.nix
        ../dev/ai/prompts/ethics.nix
        ../dev/ai/prompts/no-tests.nix
        ../dev/ai/prompts/no-comments.nix
        ../dev/ai/claude-code/claude-code.nix
        ../dev/ai/paseo/options.nix
        ../dev/ai/paseo/service.nix
        ../tools/git.nix
        ../tools/tmux.nix
        ../hosts/y0usaf-server/tools.nix
      ];
  };

  desktopPersistent = mkFinixSystem {
    cudaSupport = true;
    modules =
      [
        inputs.finix.nixosModules.networkmanager
        inputs.finix.nixosModules.nix-daemon
        inputs.finix.nixosModules.nftables
        inputs.finix.nixosModules.limine
      ]
      ++ [
        ./diagnostics.nix
        inputs.manzil.finixModules.default
      ]
      ++ desktopModules;
  };
  frameworkPersistent = mkFinixSystem {
    modules =
      [
        inputs.finix.nixosModules.brightnessctl
        inputs.finix.nixosModules.docker
        inputs.finix.nixosModules.fwupd
        inputs.finix.nixosModules.networkmanager
        inputs.finix.nixosModules.nftables
        inputs.finix.nixosModules.nix-daemon
        inputs.finix.nixosModules.power-profiles-daemon
        inputs.finix.nixosModules.zzz
      ]
      ++ [
        ./diagnostics.nix
        inputs.manzil.finixModules.default
      ]
      ++ frameworkModules;
  };

  bootPackage =
    (config.finix.mkIsland {
      name = "finix-server-boot";
      system = serverPersistent.config.system.topLevel;
      ucodeImg = "${pkgs.microcode-intel}/intel-ucode.img";
      defaultHost = "server";
    }).bootDriverScript;

  persistentDeployPackage =
    (config.finix.mkDeploy {
      name = "finix-server-persistent-deploy";
      system = serverPersistent.config.system.topLevel;
      defaultHost = "server";
      bootDriverName = "finix-server-boot";
      sshHost = "100.105.204.116";
      sshPort = 22;
    }).deployScript;

  desktopDeployPackage =
    (config.finix.mkDeploy {
      name = "finix-desktop-deploy";
      system = desktopPersistent.config.system.topLevel;
      defaultHost = "local";
    }).deployScript;
in {
  imports = [./finixSystem.nix ./deploy.nix ./esp-island.nix];
  options.finix = {
    hosts = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      description = "Evaluated Finix host configurations.";
    };
    packages = lib.mkOption {
      type = lib.types.attrsOf lib.types.package;
      description = "Host deployment and boot tools.";
    };
  };
  config.finix.hosts = {
    y0usaf-desktop = desktopPersistent;
    y0usaf-framework = frameworkPersistent;
    y0usaf-server = serverPersistent;
  };

  config.finix.packages = {
    finix-server-persistent-deploy = persistentDeployPackage;
    finix-server-boot = bootPackage;
    finix-desktop-deploy = desktopDeployPackage;
  };
}
