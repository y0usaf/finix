# Finix — the installed OS on server (2026-07-15) and desktop; NixOS remains
# on disk as rescue until the purge (NOTES.md runbook). Everything finix
# lives in THIS folder: default.nix (systems + packages), the boot/deploy
# drivers, common.nix baseline, diagnostics.nix, hosts/, NOTES.md.
#
# Day-2 operations:
#   desktop:  nh os switch            full flow — build → activate → profile
#                                     generation → Limine menu render (upstream
#                                     programs.limine owns /boot, hosts/y0usaf-desktop/boot.nix)
#             fx test                 runtime-only trial, never touches boot
#   server:   nix run .#finix-server-persistent-deploy -- 192.168.2.66 test|switch
#             kernel/initrd/cmdline:  nix run .#finix-server-boot -- 192.168.2.66 install
#                                     ... oneshot, health checks, ... promote
#             status/rescue:          nix run .#finix-server-boot -- 192.168.2.66 status|demote|rollback
{
  inputs,
  system,
}: let
  # pkgs parity with the (now deleted) NixOS bridge: same unfree/insecure
  # policy, cudaSupport, and overlays as modules/core/nixpkgs.nix, so the
  # compat-imported package declarations build against an equivalent pkgs.
  permittedInsecurePackages = [
    "qtwebengine-5.15.19"
    "electron-38.8.4"
    "openssl-1.1.1w"
    "nodejs-20.20.2"
    "nodejs-slim-20.20.2"
  ];
  pkgs = import inputs.nixpkgs {
    inherit system;
    config = {
      allowUnfree = true;
      cudaSupport = true;
      inherit permittedInsecurePackages;
      allowInsecurePredicate = pkg:
        builtins.elem (pkg.name or "${pkg.pname or "name-missing"}-${pkg.version or "version-missing"}") permittedInsecurePackages
        || lib.hasPrefix "librewolf" (pkg.pname or "")
        || lib.hasPrefix "electron" (pkg.pname or "");
    };
    overlays = [
      inputs.claude-code-nix.overlays.default
      # n8n 2.31.4's GitHub archive FOD hash drifted (GitHub repacks tag
      # tarballs; gzip bytes aren't stable). Re-pin with the current bytes.
      # Pre-existing breakage unrelated to our changes — drop when nixpkgs
      # bumps past it.
      (final: prev: {
        n8n = prev.n8n.overrideAttrs (old: {
          src = final.fetchFromGitHub {
            owner = "n8n-io";
            repo = "n8n";
            rev = "n8n@${old.version}";
            hash = "sha256-lmkCT1o5LSC1ORd+Jozr9hkJu2znMpFO97jTWYOnga0=";
          };
        });
      })
    ];
  };
  inherit (pkgs) lib;

  # Shared builder for every finix system in this repo. finix uses its own
  # module system (finit/providers option tree) — NixOS modules under
  # ../modules are consumed ONLY through finix/compat-import.nix (whitelist
  # shim: user/manzil/environment/fonts + services.udev.packages). Baseline:
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
          # NixOS declares config.lib (nixpkgs lib as an option); our
          # modules extend it with custom generators (toTOML/toLua/toKDL/
          # toNiriconf) and reference config.lib.generators in manzil file
          # generators. finix has no such option — stub it. DEEP freeform:
          # plain types.attrs merges shallow (later `generators` def would
          # silently overwrite earlier ones).
          {
            options.lib = lib.mkOption {
              type = lib.types.submodule {freeformType = lib.types.attrsOf (lib.types.attrsOf lib.types.unspecified);};
              default = {};
            };
          }
          # NixOS-only option stubs referenced by guards in kept config.
          # Values mirror the desktop's bridge-era reality (bluetooth + amdgpu
          # on; server services + lix off).
          {
            options.boot.loader.limine.secureBoot.enable = lib.mkEnableOption "";
            options.services = {
              mediamtx.enable = lib.mkEnableOption "";
              forgejo.enable = lib.mkEnableOption "";
              n8n.enable = lib.mkEnableOption "";
              nginx.enable = lib.mkEnableOption "";
            };
            options.programs = {
              lix.enable = lib.mkEnableOption "";
              tweakcc.enable = lib.mkEnableOption "";
            };
            options.hardware = {
              bluetooth.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              amdgpu.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
            };
            # Referenced by gaming/shader-cache.nix's steam_dev.cfg manzil
            # entry; mirrors modules/core/system/nix-package-management.nix.
            options.nix.settings.max-jobs = lib.mkOption {
              type = lib.types.str;
              default = "auto";
            };
          }
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

  compatImport = import ./compat-import.nix {inherit lib;};

  # The desktop's shared config library: every .nix under the NixOS domain
  # tree + the desktop host dir, shimmed through compat-import. Exclusions:
  #   - flake-modules.nix wires NixOS-only input modules (manzil.nixosModules
  #     would collide with the finix variant imported below)
  #   - hosts/y0usaf-desktop/finix/ is already finix-native
  compatRoots = [
    ../modules/core
    ../modules/desktop
    ../modules/shell
    ../modules/tools
    ../modules/user-services
    ../modules/dev
    ../modules/gaming
    ../hosts/y0usaf-desktop
  ];
  compatExclusions = [
    ../modules/core/flake-modules.nix
  ];
  compatFiles =
    builtins.filter (p:
      !(builtins.elem p compatExclusions)
      && !(lib.hasInfix "/finix/" (toString p)))
    (import ../recursivelyImport.nix {
        inherit (lib) hasSuffix;
        inherit (lib.filesystem) listFilesRecursive;
      }
      compatRoots);
  compatModules = map compatImport compatFiles;

  # ── systems ──────────────────────────────────────────────────────────────
  serverPersistent = mkFinixSystem (with inputs.finix.nixosModules; [
    cron
    nftables
    postgresql
    nix-daemon
    ../hosts/y0usaf-server/finix/services.nix
    ../hosts/y0usaf-server/finix/persistent.nix
    ../hosts/y0usaf-server/finix/attic.nix
  ]);

  desktopPersistent = mkFinixSystem (with inputs.finix.nixosModules;
    [
      nix-daemon
      limine # upstream bootloader: ../hosts/y0usaf-desktop/finix/boot.nix (OFF on server)
      ./diagnostics.nix
      ../hosts/y0usaf-desktop/finix/persistent.nix
      inputs.manzil.finixModules.default
    ]
    ++ compatModules);

  # ── drivers ──────────────────────────────────────────────────────────────
  islandLib = import ./esp-island.nix {inherit pkgs lib;};
  deployLib = import ./deploy.nix {inherit pkgs;};
in rec {
  inherit serverPersistent desktopPersistent;

  bootPackage =
    (islandLib.mkIsland {
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
}
