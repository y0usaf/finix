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
    ../dev/kimi-code/package.nix
    ../dev/paseo/options.nix
    ../dev/paseo/service.nix
    ../dev/paseo/desktop.nix
    # Phi prompt body is data imported by pi and phi prompt modules.
    ../dev/phi/prompt-body.nix
    ../dev/skills/mapping.nix
    ../dev/pi/model-catalog.nix
    ../dev/skills/codebase-atlas/SKILL.nix
    ../dev/skills/ship/SKILL.nix
    ../dev/skills/anti-slop/SKILL.nix
    # Shared persistence is still imported as data by host policy modules.
    ../hosts/common/persist.nix
  ];
  mkGraphicalModules = hostDir:
    map import (builtins.filter (path:
        !(builtins.elem path walkedKnownExclusions)
        && !(lib.hasInfix "/finix/" (toString path))
        && !(lib.hasSuffix "/impermanence.nix" (toString path)))
      (recursivelyImport [
        ../core
        ../desktop
        ../dev
        ../gaming
        ../shell
        ../tools
        ../user-services
        ../hosts/common
        hostDir
      ]));
  desktopModules = mkGraphicalModules ../hosts/y0usaf-desktop;
  frameworkModules = mkGraphicalModules ../hosts/y0usaf-framework;

  # Nix has no destructuring let-binding; bind the module and inherit the
  # names (lib is already bound above; nixpkgs.lib === the builder's lib).
  finixSystem = import ./finixSystem.nix {inherit inputs system;};
  inherit (finixSystem) pkgs mkFinixSystem;
  deployLib = import ./deploy.nix {inherit pkgs;};

  # NOTE: mkFinixSystem imports ./common.nix in its baseline (shared by
  # every system, kept in the old position for exact module-order parity).

  serverPersistent = mkFinixSystem (
    (with inputs.finix.nixosModules; [
      cron
      nftables
      postgresql
      nix-daemon
    ])
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
      # Server-only modules that are not part of the graphical module walk.
      (import ../core/user/user-config.nix)
      (import ../dev/claude-code/claude-code.nix)
      # paseo daemon options and finit service.
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
      (import ../tools/git.nix)
      (import ../hosts/y0usaf-server/tools.nix)
    ]
  );

  desktopPersistent = mkFinixSystem (
    (with inputs.finix.nixosModules; [
      nix-daemon
      # The desktop packet filter is a Finix-native module imported below.
      nftables
      limine # upstream bootloader: ../../hosts/y0usaf-desktop/finix/boot.nix (OFF on server)
    ])
    ++ [
      ./diagnostics.nix
      ../hosts/y0usaf-desktop/finix/persistent.nix
      inputs.manzil.finixModules.default
      firewall
      # paseo daemon options and finit service.
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
      # paseo desktop app.
      (import ../dev/paseo/desktop.nix)
    ]
    ++ desktopModules
  );

  frameworkPersistent = mkFinixSystem (
    (with inputs.finix.nixosModules; [
      brightnessctl
      docker
      fwupd
      networkmanager
      nftables
      nix-daemon
      power-profiles-daemon
      zzz
    ])
    ++ [
      ./diagnostics.nix
      ../hosts/y0usaf-framework/finix/persistent.nix
      inputs.manzil.finixModules.default
    ]
    ++ frameworkModules
  );

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
      sshHost = "192.168.2.66";
      sshPort = 2200;
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
in rec {
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
