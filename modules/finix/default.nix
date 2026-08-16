{
  inputs,
  system,
}: let
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  # finix-native modules (no shim) cannot be walked; the desktop packet
  # filter is one and is imported directly below.
  firewall = import ../core/firewall.nix;

  # Desktop: bulk-import every module in the shared tree (already finix-
  # consumed; the fleet stripped NixOS-only config) + the desktop host dir's
  # legacy files. Exclusions:
  #   - ../core/firewall.nix  (finix-native nftables, imported directly)
  #   - ../dev/kimi-code/package.nix (package function, not a module)
  #   - ../dev/paseo/options.nix + service.nix (finix-native finit service)
  #   - **/SKILL.nix data files and mapping.nix (non-module data)
  #   - hosts/…/impermanence.nix (NixOS-only)
  #   - any path containing /finix/  (already finix-native)
  recursivelyImport = import ../../recursivelyImport.nix {inherit lib;};
  walkedKnownExclusions = [
    ../core/firewall.nix
    ../dev/kimi-code/package.nix
    ../dev/paseo/options.nix
    ../dev/paseo/service.nix
    ../dev/skills/mapping.nix
    # SKILL.nix files are bare-string data (the shim dropped them as
    # non-function modules); their content is consumed via direct import in
    # ship.nix / codebase-atlas.nix, so exclude them from the walk.
    ../dev/skills/codebase-atlas/SKILL.nix
    ../dev/skills/ship/SKILL.nix
    ../dev/skills/anti-slop/SKILL.nix
    # environment.persistence is NixOS-only; this file's persist list is
    # replayed as plain bind mounts by hosts/y0usaf-desktop/finix/*.
    ../../hosts/y0usaf-desktop/impermanence.nix
  ];
  desktopNixosModules = map import (builtins.filter (p:
      !(builtins.elem p walkedKnownExclusions)
      && !(lib.hasInfix "/finix/" (toString p)))
    (recursivelyImport [
      ../core
      ../desktop
      ../dev
      ../gaming
      ../shell
      ../tools
      ../user-services
      ../../hosts/y0usaf-desktop
    ]));

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
      ../../hosts/y0usaf-server/finix/services.nix
      ../../hosts/y0usaf-server/finix/persistent.nix
      ../../hosts/y0usaf-server/finix/attic.nix
      ../../hosts/y0usaf-server/finix/boot-health.nix
      ../../hosts/y0usaf-server/finix/boot.nix
      ../../hosts/y0usaf-server/finix/hermes.nix
      ../../hosts/y0usaf-server/finix/paseo.nix
      inputs.manzil.finixModules.default
      # rewrite every entry every switch (watcher invalidation)
      {manzil.forceByDefault = true;}
      # Shared modules the server needs, imported explicitly, in the same
      # order the old recursive walk produced them (core/user-config, then
      # dev/claude-code, dev/paseo, then tools/git) so the server closure is
      # unchanged. user-config / claude-code / git are finix-consumed only;
      # git is enabled here because the server has no tools.nix (desktop
      # sets it in hosts/y0usaf-desktop/tools.nix; idempotent).
      (import ../core/user/user-config.nix)
      # claude-code module + settings (finix-consumed)
      (import ../dev/claude-code/claude-code.nix)
      (import ../dev/claude-code/settings.nix)
      # paseo daemon options + finit service (finix-native). The server's
      # paseo.nix above enables it; the desktop imports the same two files
      # explicitly in desktopPersistent (the recursive walk excludes them).
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
      (import ../tools/git.nix)
      {user.tools.git.enable = true;}
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
      ../../hosts/y0usaf-desktop/finix/persistent.nix
      inputs.manzil.finixModules.default
      # rewrite every entry every switch (watcher invalidation)
      {manzil.forceByDefault = true;}
      firewall
      # paseo daemon options + finit service (finix-native; same pattern as
      # serverPersistent). Declares user.dev.paseo, gated on
      # enable, which hosts/y0usaf-desktop/dev.nix sets.
      (import ../dev/paseo/options.nix)
      (import ../dev/paseo/service.nix)
    ]
    ++ desktopNixosModules
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
