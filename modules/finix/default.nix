{
  inputs,
  system,
}: let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  # finix-native modules (no shim) cannot be walked; the desktop packet
  # filter is one and is imported directly below.
  firewall = import ../core/firewall.nix;

  # Shared definitions and selected host policy are both discovered
  # recursively. Native finix host modules are imported explicitly; persistence
  # allowlists remain data until they become ordinary modules.
  recursivelyImport = import ../../recursivelyImport.nix {inherit lib;};
  walkedKnownExclusions = [
    ../core/firewall.nix
    ../dev/ai/kimi-code/package.nix
    ../dev/ai/paseo/options.nix
    ../dev/ai/paseo/service.nix
    ../dev/ai/paseo/desktop.nix
    # Phi prompt body is data imported by pi and phi prompt modules.
    ../dev/ai/phi/prompt-body.nix
    ../dev/ai/prompts/mapping.nix
    ../dev/ai/pi/model-catalog.nix
    ../dev/ai/prompts/codebase-atlas/SKILL.nix
    ../dev/ai/prompts/ship/SKILL.nix
    ../dev/ai/prompts/anti-slop/SKILL.nix
    # Shared persistence is still imported as data by host policy modules.
    ../hosts/common/persist.nix
  ];
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
  filterGraphicalModule = path:
    !(builtins.elem path walkedKnownExclusions)
    && !(lib.hasInfix "/finix/" (toString path))
    && !(lib.hasSuffix "/impermanence.nix" (toString path));
  commonGraphicalModules = map import (builtins.filter filterGraphicalModule (recursivelyImport graphicalRoots));
  hostGraphicalModules = hostDir: map import (builtins.filter filterGraphicalModule (recursivelyImport [hostDir]));
  desktopModules = commonGraphicalModules ++ hostGraphicalModules ../hosts/y0usaf-desktop;
  frameworkModules = commonGraphicalModules ++ hostGraphicalModules ../hosts/y0usaf-framework;

  # Nix has no destructuring let-binding; bind the module and inherit the
  # names (lib is already bound above; nixpkgs.lib === the builder's lib).
  finixSystem = import ./finixSystem.nix {inherit inputs system;};
  inherit (finixSystem) basePkgs mkFinixSystem;
  pkgs = basePkgs;
  deployLib = import ./deploy.nix {inherit lib pkgs;};

  # NOTE: mkFinixSystem imports ./common.nix in its baseline (shared by
  # every system, kept in the old position for exact module-order parity).

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
        ../hosts/y0usaf-server/finix/hermes.nix
        ../hosts/y0usaf-server/finix/paseo.nix
        inputs.manzil.finixModules.default
        (import ../hosts/common/finix-base.nix)
        (import ../hosts/common/finix-btrfs.nix)
        (import ../hosts/common/finix-identity.nix)
        (import ../hosts/common/finix-nix-daemon.nix)
        (import ../hosts/common/manzil.nix)
        (import ../hosts/common/ssh-keys.nix)
        (import ../core/user/user-config.nix)
        (import ../dev/ai/claude-code/claude-code.nix)
        (import ../dev/ai/paseo/options.nix)
        (import ../dev/ai/paseo/service.nix)
        (import ../tools/git.nix)
        (import ../tools/tmux.nix)
        (import ../hosts/y0usaf-server/tools.nix)
      ];
  };

  desktopPersistent = mkFinixSystem {
    cudaSupport = true;
    modules =
      [
        inputs.finix.nixosModules.nix-daemon
        inputs.finix.nixosModules.nftables
        inputs.finix.nixosModules.limine
      ]
      ++ [
        ./diagnostics.nix
        ../hosts/y0usaf-desktop/finix/persistent.nix
        inputs.manzil.finixModules.default
        firewall
        (import ../dev/ai/paseo/options.nix)
        (import ../dev/ai/paseo/service.nix)
        (import ../dev/ai/paseo/desktop.nix)
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
        ../hosts/y0usaf-framework/finix/persistent.nix
        inputs.manzil.finixModules.default
      ]
      ++ frameworkModules;
  };

  # Deployment and boot outputs below remain tied to their target systems.

  bootPackage =
    ((import ./esp-island.nix {inherit pkgs lib;}).mkIsland {
      name = "finix-server-boot";
      system = serverPersistent.config.system.topLevel;
      # ADL-N BIOS ships ancient 0x1a microcode; both raw direct boots
      # misbehaved until 0x21 was prepended (incident #2).
      ucodeImg = "${pkgs.microcode-intel}/intel-ucode.img";
      defaultHost = "server";
    }).bootDriverScript;

  persistentDeployPackage =
    (deployLib.mkDeploy {
      name = "finix-server-persistent-deploy";
      system = serverPersistent.config.system.topLevel;
      defaultHost = "server";
      # Server boot slots are managed by the Finix ESP island driver.
      bootDriverName = "finix-server-boot";
      # Root's ssh key is authorized ONLY via the tailnet IP (LAN root@:2200
      # denies it; y0usaf@ works everywhere). Deploy as root@tailnet:22.
      sshHost = "100.105.204.116";
      sshPort = 22;
    }).deployScript;

  desktopDeployPackage =
    (deployLib.mkDeploy {
      name = "finix-desktop-deploy";
      system = desktopPersistent.config.system.topLevel;
      defaultHost = "local";
      # No postSwitch: stc switch|boot runs the limine installHook itself
      # (boot.nix). Only `fx test` (runtime-only, no installHook) and
      # manual stc invocations go through this package anymore.
    }).deployScript;
in {
  hosts = {
    y0usaf-desktop = desktopPersistent;
    y0usaf-framework = frameworkPersistent;
    y0usaf-server = serverPersistent;
  };

  packages = {
    finix-server-persistent-deploy = persistentDeployPackage;
    finix-server-boot = bootPackage;
    finix-desktop-deploy = desktopDeployPackage;
  };
}
