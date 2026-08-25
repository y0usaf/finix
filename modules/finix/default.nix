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
  desktopNixosModules = mkGraphicalModules ../hosts/y0usaf-desktop;
  frameworkNixosModules = mkGraphicalModules ../hosts/y0usaf-framework;

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
      # Staged, disarmed: boot.nix pins programs.limine.enable = false, so this
      # module is inert (upstream guards its config block on cfg.enable) and the
      # server closure is unchanged. Imported so the takeover config evaluates
      # on every deploy instead of rotting. The ESP island still owns boot.
      limine
    ])
    ++ [
      ../hosts/y0usaf-server/finix/services.nix
      ../hosts/y0usaf-server/finix/persistent.nix
      ../hosts/y0usaf-server/finix/attic.nix
      ../hosts/y0usaf-server/finix/boot-health.nix
      ../hosts/y0usaf-server/finix/boot.nix
      ../hosts/y0usaf-server/finix/hermes.nix
      ../hosts/y0usaf-server/finix/paseo.nix
      inputs.manzil.finixModules.default
      (import ../hosts/common/finix-base.nix)
      (import ../hosts/common/finix-btrfs.nix)
      (import ../hosts/common/finix-identity.nix)
      (import ../hosts/common/finix-nix-daemon.nix)
      (import ../hosts/common/manzil.nix)
      (import ../hosts/common/ssh-keys.nix)
      # Shared modules the server needs, imported explicitly, in the same
      # order the old recursive walk produced them (core/user-config, then
      # dev/claude-code, dev/paseo, then tools/git) so the server closure is
      # unchanged. user-config / claude-code / git are finix-consumed only;
      # git is enabled here because the server has no tools.nix (desktop
      # sets it in hosts/y0usaf-desktop/tools.nix; idempotent).
      (import ../core/user/user-config.nix)
      (import ../dev/claude-code/claude-code.nix)
      # paseo daemon options + finit service (finix-native). The server's
      # paseo.nix above enables it; the desktop imports the same two files
      # explicitly in desktopPersistent (the recursive walk excludes them).
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
      (import ../tools/git.nix)
      (import ../hosts/y0usaf-server/tools.nix)
    ]
  );

  desktopPersistent = mkFinixSystem (
    (with inputs.finix.nixosModules; [
      nix-daemon
      # Packet filter. Was serverPersistent-only until 2026-07-30, which is why
      # the desktop ran unfiltered since the finix switch (DRIFT-AUDIT #1).
      # Ruleset: ../core/firewall.nix (finix-native, imported directly below).
      nftables
      limine # upstream bootloader: ../../hosts/y0usaf-desktop/finix/boot.nix (OFF on server)
    ])
    ++ [
      ./diagnostics.nix
      ../hosts/y0usaf-desktop/finix/persistent.nix
      inputs.manzil.finixModules.default
      firewall
      # paseo daemon options + finit service (finix-native; same pattern as
      # serverPersistent). Declares user.dev.paseo, gated on
      # enable, which hosts/y0usaf-desktop/dev.nix sets.
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
      # paseo desktop app (GUI-only; the server has no desktop). Declares
      # user.dev.paseo.desktop, gated on enable, which
      # hosts/y0usaf-desktop/dev.nix sets.
      (import ../dev/paseo/desktop.nix)
    ]
    ++ desktopNixosModules
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
    ++ frameworkNixosModules
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

  frameworkBootPackage =
    ((import ./esp-island.nix {inherit pkgs lib;}).mkIsland {
      name = "finix-framework-boot";
      system = frameworkPersistent.config.system.topLevel;
      ucodeImg = "${pkgs.microcode-amd}/amd-ucode.img";
      defaultHost = "local";
    }).bootDriverScript;

  persistentDeployPackage =
    (deployLib.mkDeploy {
      name = "finix-server-persistent-deploy";
      system = serverPersistent.config.system.topLevel;
      defaultHost = "server";
      # Boot slots on the server belong to the ESP island driver, not stc.
      bootDriverName = "finix-server-boot";
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
    finix-framework-boot = frameworkBootPackage;
  };
}
