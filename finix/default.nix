# Finix - the server's installed OS since 2026-07-15 (NixOS stays on disk
# as the rescue entry). See NOTES.md for the full migration record.
#
# Layout:
#   lib/      mk-system.nix (builder), esp-island.nix (boot driver),
#             deploy.nix (SSH config deploys)
#   modules/  common.nix baseline + upstream-bug workarounds
#   hosts/    per-machine finix systems (y0usaf-server; desktop someday)
#   attic/    retired kexec-era tooling (vm, trial, beacon, kexec drivers)
#
# Day-2 operations:
#   config-only change:  nix run .#finix-server-persistent-deploy -- 192.168.2.66 test|switch
#   kernel/initrd/cmdline change:  nix run .#finix-server-boot -- 192.168.2.66 install
#                                  ... oneshot, health checks, ... promote
#   status/rescue:  nix run .#finix-server-boot -- 192.168.2.66 status|demote|rollback
{
  inputs,
  system,
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
    # n8n ships under the (unfree) Sustainable Use License.
    config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or pkg.name) ["n8n"];
  };
  inherit (pkgs) lib;

  mkFinixSystem = import ./lib/mk-system.nix {inherit inputs pkgs lib;};

  # ── systems ──────────────────────────────────────────────────────────────
  serverPersistent = mkFinixSystem (with inputs.finix.nixosModules; [
    cron
    nftables
    postgresql
    nix-daemon
    ./hosts/y0usaf-server/services.nix
    ./hosts/y0usaf-server/persistent.nix
  ]);

  # Retired-era systems (attic); kept buildable, not part of any boot path.
  serverVm = mkFinixSystem [
    # Not exported by name from finix's module set; import by path.
    "${inputs.finix.outPath}/modules/virtualisation/qemu.nix"
    ./attic/server-vm.nix
  ];

  serverTrial = mkFinixSystem (with inputs.finix.nixosModules; [
    cron
    nftables
    postgresql
    ./hosts/y0usaf-server/services.nix
    ./attic/server-trial.nix
  ]);

  # ── drivers ──────────────────────────────────────────────────────────────
  island = import ./lib/esp-island.nix {inherit pkgs lib serverPersistent;};
  deploy = import ./lib/deploy.nix {inherit pkgs serverPersistent;};
  attic = import ./attic/drivers.nix {
    inherit pkgs lib serverVm serverTrial serverPersistent;
  };
in {
  inherit serverVm serverTrial serverPersistent;

  persistentPackage =
    pkgs.runCommand "finix-server-persistent" {
      meta.mainProgram = "finix-server-persistent";
    } ''
      mkdir -p $out/bin
      ln -s ${serverPersistent.config.system.topLevel} $out/system
    '';

  bootPackage =
    pkgs.runCommand "finix-server-boot" {
      meta.mainProgram = "finix-server-boot";
    } ''
      mkdir -p $out/bin
      ln -s ${island.bootDriverScript}/bin/finix-server-boot $out/bin/finix-server-boot
    '';

  persistentDeployPackage =
    pkgs.runCommand "finix-server-persistent-deploy" {
      meta.mainProgram = "finix-server-persistent-deploy";
    } ''
      mkdir -p $out/bin
      ln -s ${deploy.persistentDeployScript}/bin/finix-server-persistent-deploy $out/bin/finix-server-persistent-deploy
    '';

  # ── attic packages (retired kexec era; see attic/drivers.nix) ────────────
  vmPackage =
    pkgs.runCommand "finix-server-vm" {
      meta.mainProgram = "run-finix-server-vm";
    } ''
      mkdir -p $out/bin
      ln -s ${serverVm.config.system.topLevel} $out/system
      ln -s ${attic.runVmScript}/bin/run-finix-server-vm $out/bin/run-finix-server-vm
    '';

  trialPackage =
    pkgs.runCommand "finix-server-trial" {
      meta.mainProgram = "finix-server-trial";
    } ''
      mkdir -p $out/bin
      ln -s ${serverTrial.config.system.topLevel} $out/system
      ln -s ${attic.trialScript}/bin/finix-server-trial $out/bin/finix-server-trial
    '';

  persistentKexecPackage =
    pkgs.runCommand "finix-server-persistent-kexec" {
      meta.mainProgram = "finix-server-persistent-kexec";
    } ''
      mkdir -p $out/bin
      ln -s ${attic.persistentKexecScript}/bin/finix-server-persistent-kexec $out/bin/finix-server-persistent-kexec
    '';
}
