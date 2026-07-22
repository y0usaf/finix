# Finix - the server's installed OS since 2026-07-15 (NixOS stays on disk
# as the rescue entry); the desktop is migrating the same way (phase 1:
# console skeleton). See NOTES.md for the full record.
#
# Layout:
#   lib/      mk-system.nix (builder), esp-island.nix (boot driver),
#             deploy.nix (SSH/local config deploys)
#   modules/  common.nix baseline + workarounds, diagnostics.nix
#   hosts/    per-machine finix systems (y0usaf-server, y0usaf-desktop)
#   attic/    retired kexec-era tooling (vm, trial, beacon, kexec drivers)
#
# Day-2 operations (server; desktop mirrors with finix-desktop-* + `local`):
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
    config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or pkg.name) ["n8n" "nvidia-x11" "nvidia-kernel-modules"];
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

  desktopPersistent = mkFinixSystem (with inputs.finix.nixosModules; [
    nix-daemon
    ./modules/diagnostics.nix
    ./hosts/y0usaf-desktop/persistent.nix
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
  islandLib = import ./lib/esp-island.nix {inherit pkgs lib;};
  deployLib = import ./lib/deploy.nix {inherit pkgs;};

  attic = import ./attic/drivers.nix {
    inherit pkgs lib serverVm serverTrial serverPersistent;
  };

  binPackage = name: script:
    pkgs.runCommand name {meta.mainProgram = name;} ''
      mkdir -p $out/bin
      ln -s ${script}/bin/${name} $out/bin/${name}
    '';
in {
  inherit serverVm serverTrial serverPersistent desktopPersistent;

  persistentPackage =
    pkgs.runCommand "finix-server-persistent" {
      meta.mainProgram = "finix-server-persistent";
    } ''
      mkdir -p $out/bin
      ln -s ${serverPersistent.config.system.topLevel} $out/system
    '';

  desktopPersistentPackage =
    pkgs.runCommand "finix-desktop-persistent" {
      meta.mainProgram = "finix-desktop-persistent";
    } ''
      mkdir -p $out/bin
      ln -s ${desktopPersistent.config.system.topLevel} $out/system
    '';

  bootPackage =
    binPackage "finix-server-boot"
    (islandLib.mkIsland {
      name = "finix-server-boot";
      system = serverPersistent.config.system.topLevel;
      # ADL-N BIOS ships ancient 0x1a microcode; both raw direct boots
      # misbehaved until 0x21 was prepended (incident #2).
      ucodeImg = "${pkgs.microcode-intel}/intel-ucode.img";
      defaultHost = "server";
    }).bootDriverScript;
  desktopBootPackage =
    binPackage "finix-desktop-boot"
    (islandLib.mkIsland {
      name = "finix-desktop-boot";
      system = desktopPersistent.config.system.topLevel;
      ucodeImg = "${pkgs.microcode-amd}/amd-ucode.img";
      # The desktop drives its own ESP: island script runs locally under sudo.
      defaultHost = "local";
    }).bootDriverScript;

  persistentDeployPackage =
    binPackage "finix-server-persistent-deploy"
    (deployLib.mkDeploy {
      name = "finix-server-persistent-deploy";
      system = serverPersistent.config.system.topLevel;
      defaultHost = "server";
    }).deployScript;
  desktopDeployPackage =
    binPackage "finix-desktop-deploy"
    (deployLib.mkDeploy {
      name = "finix-desktop-deploy";
      system = desktopPersistent.config.system.topLevel;
      defaultHost = "local";
    }).deployScript;

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
