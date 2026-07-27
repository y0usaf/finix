# Finix — the installed OS on server (2026-07-15) and desktop; NixOS remains
# on disk as rescue until the purge (NOTES.md runbook). Everything finix
# lives in THIS folder: default.nix (systems + packages), the boot/deploy
# drivers, common.nix baseline, diagnostics.nix, hosts/, NOTES.md.
#
# Day-2 operations (server; desktop mirrors with finix-desktop-* + `local`):
#   config-only change:  nix run .#finix-server-persistent-deploy -- 192.168.2.66 test|switch
#                        (desktop: nix run .#finix-desktop-deploy -- local switch
#                        alone — it chains the boot-slot staging; nh os switch parity)
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

  # Shared builder for every finix system in this repo. finix uses its own
  # module system (finit/providers option tree) — NixOS modules under
  # ../../modules are NOT importable here and never will be. Baseline:
  # bash, dhcpcd, getty, openssh, sudo, sysklogd + common.nix workarounds
  # (see NOTES.md "Upstream finix bugs/gaps").
  mkFinixSystem = modules:
    inputs.finix.lib.finixSystem {
      inherit lib;
      specialArgs = {
        modulesPath = toString inputs.nixpkgs + "/nixos/modules";
        # Flake inputs for hosts that pull packages from them (e.g. pi).
        flakeInputs = inputs;
      };
      modules = with inputs.finix.nixosModules;
        [
          {nixpkgs.pkgs = lib.mkDefault pkgs;}
          bash
          dhcpcd
          getty
          openssh
          sudo
          sysklogd
          ./common.nix
        ]
        ++ modules;
    };

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
    ./diagnostics.nix
    ./hosts/y0usaf-desktop/persistent.nix
  ]);

  # ── drivers ──────────────────────────────────────────────────────────────
  islandLib = import ./esp-island.nix {inherit pkgs lib;};
  deployLib = import ./deploy.nix {inherit pkgs;};
in rec {
  inherit serverPersistent desktopPersistent;

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
    (islandLib.mkIsland {
      name = "finix-server-boot";
      system = serverPersistent.config.system.topLevel;
      # ADL-N BIOS ships ancient 0x1a microcode; both raw direct boots
      # misbehaved until 0x21 was prepended (incident #2).
      ucodeImg = "${pkgs.microcode-intel}/intel-ucode.img";
      defaultHost = "server";
    }).bootDriverScript;

  desktopBootPackage =
    ((import ./limine-entries.nix {inherit pkgs lib;}).mkLimineEntries {
      name = "finix-desktop-boot";
      system = desktopPersistent.config.system.topLevel;
      ucodeImg = "${pkgs.microcode-amd}/amd-ucode.img";
    }).bootDriverScript;

  persistentDeployPackage =
    (deployLib.mkDeploy {
      name = "finix-server-persistent-deploy";
      system = serverPersistent.config.system.topLevel;
      defaultHost = "server";
    }).deployScript;

  desktopDeployPackage =
    (deployLib.mkDeploy {
      name = "finix-desktop-deploy";
      system = desktopPersistent.config.system.topLevel;
      defaultHost = "local";
      # nh os switch parity: a successful switch also stages the boot slot
      # (kernel/initrd/limine.conf + enroll/sign), so the reboot default
      # follows the deploy. The boot driver self-sudos.
      postSwitch = "${desktopBootPackage}/bin/finix-desktop-boot local install";
    }).deployScript;
}
