{
  inputs,
  system,
}: let
  inherit (inputs) nixpkgs;
  lib = nixpkgs.lib;

  # Synaptic Standard wiring: recursive import + aspect transposition.
  recursivelyImport = import ../../recursivelyImport.nix {inherit lib;};
  # transpose: {lib} -> host -> paths. Aspect files ({compat}? {finix}? hosts?)
  # carry both universes; everything else stays legacy (compat,
  # desktop-only).
  transpose = import ../../transpose.nix {inherit lib;};
  # Nix has no destructuring let-binding; bind the module and inherit the
  # names (lib is already bound above; nixpkgs.lib === the builder's lib).
  finixSystem = import ./finixSystem.nix {inherit inputs system;};
  inherit (finixSystem) pkgs mkFinixSystem;
  deployLib = import ./deploy.nix {inherit pkgs;};

  # Aspect filter shared by both hosts. Exclusions:
  #   - ../core/flake-modules.nix  (NixOS-only input modules)
  #   - ../dev/kimi-code/package.nix (package function, not a module)
  #   - any path containing /finix/  (already finix-native)
  aspectFilter =
    builtins.filter
    (p:
      !(builtins.elem p [
        ../core/flake-modules.nix
        ../dev/kimi-code/package.nix
      ])
      && !(lib.hasInfix "/finix/" (toString p)));
  # Walk the module family dirs by name (NOT ../../modules: that recurse would
  # walk modules/finix itself), then the desktop host dir for its legacy files.
  desktopPaths = aspectFilter (recursivelyImport [../core ../desktop ../dev ../gaming ../shell ../tools ../user-services ../../hosts/y0usaf-desktop]);
  serverPaths = aspectFilter (recursivelyImport [../core ../desktop ../dev ../gaming ../shell ../tools ../user-services]);

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
      ../../hosts/y0usaf-server/finix/services.nix
      ../../hosts/y0usaf-server/finix/persistent.nix
      ../../hosts/y0usaf-server/finix/attic.nix
      ../../hosts/y0usaf-server/finix/boot-health.nix
      ../../hosts/y0usaf-server/finix/boot.nix
      ../../hosts/y0usaf-server/finix/hermes.nix
      inputs.manzil.finixModules.default
      # rewrite every entry every switch (watcher invalidation)
      {manzil.forceByDefault = true;}
    ]
    # Legacy files stay desktop-only; only aspect files with server membership land here.
    ++ transpose "server" serverPaths
  );

  desktopPersistent = mkFinixSystem (
    (with inputs.finix.nixosModules; [
      nix-daemon
      # Packet filter. Was serverPersistent-only until 2026-07-30, which is why
      # the desktop ran unfiltered since the finix switch (DRIFT-AUDIT #1).
      # Ruleset: ../core/firewall.nix.
      nftables
      limine # upstream bootloader: ../../hosts/y0usaf-desktop/finix/boot.nix (OFF on server)
    ])
    ++ [
      ./diagnostics.nix
      ../../hosts/y0usaf-desktop/finix/persistent.nix
      inputs.manzil.finixModules.default
      # rewrite every entry every switch (watcher invalidation)
      {manzil.forceByDefault = true;}
    ]
    ++ transpose "desktop" desktopPaths
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
    y0usaf-server = serverPersistent;
  };

  packages = {
    finix-server-persistent-deploy = persistentDeployPackage;
    finix-server-boot = bootPackage;
    finix-desktop-deploy = desktopDeployPackage;
  };
}
