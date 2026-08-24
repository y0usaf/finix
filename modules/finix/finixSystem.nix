# Finix — the installed OS on server (2026-07-15) and desktop; NixOS remains
# on disk as rescue until the purge (NOTES.md runbook). Host wiring — the
# finix systems and deploy/boot packages — lives in default.nix; this file
# (modules/finix/finixSystem.nix) is the shared builder only: pkgs parity +
# mkFinixSystem. The boot/deploy drivers (deploy.nix, esp-island.nix),
# diagnostics.nix, the common.nix baseline and NOTES.md sit beside it in
# modules/finix/; hosts/ at the repo root.
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
  # policy, cudaSupport, and overlays as ../core/nixpkgs.nix, so the
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
      (final: prev: {
        rush = inputs.rush.packages.${system}.default;
      })
      # Fix obs-vertical-canvas Qt6GuiPrivate cmake detection (desktop obs.nix
      # ships the plugin via obs-studio-plugins). Recovered from the deleted
      # modules/desktop/nixpkgs.nix overlay; only touches obs-vertical-canvas,
      # harmless for every other package. onnxruntime override and wrapOBS in
      # obs.nix are unaffected.
      (_: prev: let
        prevObsPlugins = prev.obs-studio-plugins;
      in {
        obs-studio-plugins =
          prevObsPlugins
          // {
            obs-vertical-canvas = prevObsPlugins.obs-vertical-canvas.overrideAttrs (old: {
              postPatch =
                (old.postPatch or "")
                + ''
                  sed -i '/find_qt(COMPONENTS Widgets COMPONENTS_LINUX Gui)/a find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)' CMakeLists.txt
                '';
            });
          };
      })
    ];
  };
  inherit (pkgs) lib;

  # Shared builder for every finix system in this repo. finix uses its own
  # module system and compatibility option tree; shared modules from sibling
  # directories are selected by default.nix. Baseline: bash, dhcpcd, getty,
  # openssh, sudo, sysklogd + ./common.nix
  # workarounds (see NOTES.md "Upstream finix bugs/gaps").
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
            options = {
              boot.loader.limine.secureBoot.enable = lib.mkEnableOption "";
              hardware.bluetooth.enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
              };
              nix.settings.max-jobs = lib.mkOption {
                type = lib.types.str;
                default = "auto";
              };
            };
            # Referenced by gaming/shader-cache.nix's steam_dev.cfg manzil
            # entry; mirrors ../core/system/nix-package-management.nix.
          }
          bash
          dhcpcd
          getty
          openssh
          # Local override of the upstream finix sudo module: the stock module
          # adds the raw (mode 0555, non-setuid) sudo binary to
          # environment.systemPackages, which shadows the setuid wrapper in
          # /run/wrappers/bin/sudo on PATH and breaks every sudo invocation
          # ("must be owned by uid 0 and have the setuid bit set"). See
          # ./sudo/default.nix. Use our stripped copy instead of
          # (inputs.finix.nixosModules.sudo).
          ./sudo
          sysklogd
          ./common.nix
          ./persistence/bind-replay.nix
          ./persistence/home-reset.nix
          ./persistence/identity.nix
        ]
        ++ modules;
    };
in {
  inherit lib pkgs mkFinixSystem;
}
