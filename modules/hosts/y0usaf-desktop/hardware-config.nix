{
  config,
  lib,
  pkgs,
  inputPackages,
  flakeInputs,
  ...
}: let
  diskUuid = "32ad19b5-88df-4e63-92d2-d5a150ad65c5";
  shared = import ../shared.nix {inherit lib;};
  btrfs = shared.btrfs diskUuid ["compress=zstd:3" "noatime" "ssd" "space_cache=v2"];
  cfg = config.programs.limine;
  emitWorld = import "${flakeInputs.luin}/nix/emit-world.nix" {
    inherit pkgs lib;
    luinc = inputPackages.luin.luinc;
    luinSrc = flakeInputs.luin;
  };
  luinitCtl = "${inputPackages.luin.luinit-ctl}/bin/luinit-ctl";
  luinitWireVer = let
    m = builtins.match ".*\\(defconst LUINIT_WIRE_VER ([0-9]+)\\).*" (builtins.readFile "${flakeInputs.luin}/lib/luinit_proto.luin");
  in
    assert lib.assertMsg (m != null) "could not parse LUINIT_WIRE_VER from luin";
      builtins.head m;
  luinitActivate = pkgs.writeShellScript "luinit-activate" ''
    [ -L /run/current-system ] && exit 0
    sys=""
    if read -r cmdline < /proc/cmdline; then
      for tok in $cmdline; do
        case "$tok" in
          luinit.system=/*) sys="''${tok#luinit.system=}" ;;
        esac
      done
    fi
    if [ -n "$sys" ] && [ -x "$sys/activate" ]; then
      exec "$sys/activate"
    fi
    exec /nix/var/nix/profiles/system/activate
  '';
  luinitWorld = emitWorld {
    name = "y0usaf-desktop-luinit-world";
    shell = "${pkgs.dash}/bin/dash";
    activateCmd = ["${luinitActivate}"];
    services = builtins.removeAttrs config.finit.services ["boot-screen"];
    tasks = builtins.removeAttrs config.finit.tasks ["ctrl-alt-del"];
    run = config.finit.run;
    ttys = config.finit.ttys;
    users = config.users.users;
    groups = config.users.groups;
  };
  luinitReload = pkgs.writeShellScript "luinit-reload" ''
    set -eu
    mode="''${LUINIT_SWITCH:-apply}"
    case "$mode" in
      0|skip|none|boot)
        echo "initctl: LUINIT_SWITCH=$mode; skipping live luinit world switch" >&2
        exit 0
        ;;
    esac
    world="$(${pkgs.coreutils}/bin/readlink -f /etc/luinit/world || true)"
    [ -x "$world" ] || {
      echo "initctl: /etc/luinit/world ($world) is not executable" >&2
      exit 1
    }
    live_ver="$(${luinitCtl} wire-ver 2>/dev/null || true)"
    if [ "$live_ver" != "${luinitWireVer}" ]; then
      echo "initctl: luinit wire version mismatch (live=''${live_ver:-unknown}, target=${luinitWireVer}); skipping live switch, reboot to activate new world" >&2
      exit 0
    fi
    if [ "$mode" = "dry-run" ] || [ "$mode" = "plan" ]; then
      tmp_dir="$(${pkgs.coreutils}/bin/mktemp -d)"
      trap '${pkgs.coreutils}/bin/rm -rf "$tmp_dir"' EXIT
      ${luinitCtl} hashes > "$tmp_dir/hashes"
      "$world" --plan > "$tmp_dir/plan"
      ${pkgs.gawk}/bin/awk '
        FNR==NR { live_pid[$1]=$3; live_hash[$1]=$4; next }
        {
          seen[$1]=1
          if (!($1 in live_hash)) print "START " $1
          else if ((live_hash[$1] "") == ($2 "")) print "KEEP " $1 " pid=" live_pid[$1]
          else if ($3 == 1 && (live_pid[$1] + 0) > 0) print "KEEP(session) " $1 " pid=" live_pid[$1]
          else print "RESTART " $1 " pid=" live_pid[$1]
        }
        END {
          for (c in live_hash) if (!(c in seen)) print "REMOVE " c " pid=" live_pid[c]
        }
      ' "$tmp_dir/hashes" "$tmp_dir/plan"
      exit 0
    fi
    exec ${luinitCtl} switch "$world"
  '';
  mkLuinitFinit = {
    plymouthSupport ? false,
    plymouth ? pkgs.plymouth,
    udevSupport ? false,
  }:
    (pkgs.finit.override {
      inherit plymouthSupport plymouth udevSupport;
    }).overrideAttrs (old: {
      configureFlags =
        (old.configureFlags or [])
        ++ lib.optional (config.finix.bootScreen.enable or false) "--enable-kernel-cmdline";
      postFixup =
        (old.postFixup or "")
        + ''
          mv "$out/bin/initctl" "$out/bin/.initctl-real"
          cat > initctl-shim.c <<EOF
          #define REAL_INITCTL "$out/bin/.initctl-real"
          #define LUINIT_CTL "${luinitCtl}"
          #define LUINIT_RELOAD "${luinitReload}"
          EOF
          cat >> initctl-shim.c <<'EOF'
          #include <string.h>
          #include <sys/stat.h>
          #include <sys/wait.h>
          #include <unistd.h>

          int main(int argc, char **argv) {
            struct stat st;
            if (stat("/run/luinit/ctl", &st) == 0 && S_ISSOCK(st.st_mode)) {
              const char *prog = argc > 0 && argv[0] ? strrchr(argv[0], '/') : 0;
              prog = prog ? prog + 1 : (argc > 0 && argv[0] ? argv[0] : "");
              if (argc == 1 && !strcmp(prog, "reboot")) {
                execl(LUINIT_CTL, "luinit-ctl", "reboot", (char *)0);
                _exit(127);
              }
              if (argc == 1 && (!strcmp(prog, "poweroff") || !strcmp(prog, "halt"))) {
                execl(LUINIT_CTL, "luinit-ctl", "poweroff", (char *)0);
                _exit(127);
              }
              if (!strcmp(prog, "initctl") && argc == 2) {
                if (!strcmp(argv[1], "reload")) {
                  execl(LUINIT_RELOAD, "luinit-reload", (char *)0);
                  _exit(127);
                }
                if (!strcmp(argv[1], "status")) {
                  execl(LUINIT_CTL, "luinit-ctl", "status", (char *)0);
                  _exit(127);
                }
                if (!strcmp(argv[1], "reboot")) {
                  execl(LUINIT_CTL, "luinit-ctl", "reboot", (char *)0);
                  _exit(127);
                }
                if (!strcmp(argv[1], "poweroff") || !strcmp(argv[1], "halt")) {
                  execl(LUINIT_CTL, "luinit-ctl", "poweroff", (char *)0);
                  _exit(127);
                }
              }
              if (!strcmp(prog, "initctl") && argc == 3) {
                if (!strcmp(argv[1], "start")) {
                  execl(LUINIT_CTL, "luinit-ctl", "mount", argv[2], (char *)0);
                  _exit(127);
                }
                if (!strcmp(argv[1], "stop")) {
                  execl(LUINIT_CTL, "luinit-ctl", "unmount", argv[2], (char *)0);
                  _exit(127);
                }
                if (!strcmp(argv[1], "restart")) {
                  pid_t pid = fork();
                  if (pid == 0) {
                    execl(LUINIT_CTL, "luinit-ctl", "unmount", argv[2], (char *)0);
                    _exit(127);
                  }
                  if (pid > 0) {
                    int st = 0;
                    waitpid(pid, &st, 0);
                  }
                  execl(LUINIT_CTL, "luinit-ctl", "mount", argv[2], (char *)0);
                  _exit(127);
                }
              }
            }
            execv(REAL_INITCTL, argv);
            _exit(127);
          }
          EOF
          "$CC" -O2 -s -Wall -Wextra -Werror initctl-shim.c -o "$out/bin/initctl"
          chmod 0755 "$out/bin/initctl"
        '';
    });
  luinitFinit = mkLuinitFinit {} // {override = mkLuinitFinit;};
  gpuUnlock = rec {
    nv = "610.43.03";
    src = pkgs.fetchFromGitHub {
      owner = "Zagitta";
      repo = "gpu-unlock";
      rev = "7eb51bccae0a0b7e599e084d971170e9a1e82d0c";
      hash = "sha256-1KD/J1S1uyI5GGoTwQ1cU/sXeEKlG54exSvi6U+j73M=";
    };
    firmware =
      pkgs.runCommand "gpu-unlock-firmware-${nv}" {
        nativeBuildInputs = [pkgs.python3 pkgs.zstd];
        installer = pkgs.fetchurl {
          url = "https://download.nvidia.com/XFree86/Linux-x86_64/${nv}/NVIDIA-Linux-x86_64-${nv}-no-compat32.run";
          sha256 = "e084451db730a6df29d3d74f655749c4d236e3c945f7d94b5205e84318fe2f90";
        };
        kernelSource = pkgs.fetchurl {
          url = "https://download.nvidia.com/XFree86/NVIDIA-kernel-module-source/NVIDIA-kernel-module-source-${nv}.tar.xz";
          sha256 = "7e118923c7a23edc36114d63273a46e3e04e9af98695a42203e7ac2dfe9fc1dc";
        };
      } ''
        tar -xf $kernelSource
        python3 ${src}/firmware/extract_gsp.py $installer assets
        python3 ${src}/firmware/extract_boot_assets.py NVIDIA-kernel-module-source-${nv} assets
        install -Dm644 -t $out/lib/firmware/gpu-unlock/${nv} assets/*.bin
      '';
    module = let
      inherit (config.boot.kernelPackages) kernel kernelModuleMakeFlags;
      kdir = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
    in
      pkgs.stdenv.mkDerivation {
        pname = "gpu-unlock";
        version = "2.0.0";
        inherit src;
        sourceRoot = "source/kernel/gpu_unlock";
        nativeBuildInputs = kernel.moduleBuildDependencies;
        makeFlags =
          kernelModuleMakeFlags
          ++ [
            "KDIR=${kdir}"
            "INSTALL_MOD_PATH=${placeholder "out"}"
            "INSTALL_MOD_DIR=extra"
            "INSTALL_MOD_STRIP=1"
            "DEPMOD=true"
          ];
        installTargets = ["modules_install"];
        installFlags = ["-C" kdir "M=$(PWD)"];
      };
  };
in {
  finix.diagnostics = {
    inherit diskUuid;
    fallbackDevices = ["/dev/nvme0n1p5"];
  };

  hardware = {
    firmware = [pkgs.linux-firmware gpuUnlock.firmware];
    cpu.amd.updateMicrocode = true;
    nvidia = {
      enable = true;
      gsp.enable = false;
    };
  };

  environment.etc."modprobe.d/nvidia-uvm.conf".text = lib.mkForce "softdep nvidia pre: gpu_unlock post: nvidia_uvm\n";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = [config.boot.kernelPackages.zenpower config.hardware.nvidia.package.mod gpuUnlock.module];
    initrd.availableKernelModules = [
      "nvme"
      "thunderbolt"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
      "k10temp"
      "nct6775"
      "zenpower"
      "igc"
    ];
    kernelParams = [
      "amd_pstate=active"
      "mitigations=off"
      "console=tty0"
      "usbcore.autosuspend=-1"
      "panic=30"
      "oops=panic"
      "softlockup_panic=1"
      "hung_task_panic=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_EnableResizableBar=1"
      "nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1"
      "nvidia_modeset.disable_vrr_memclk_switch=1"
      "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      "gpu_unlock.targets=all"
    ];
    loader.efi.canTouchEfiVariables = true;
  };

  providers.bootloader.installHook = lib.mkForce (pkgs.replaceVarsWith {
    src = pkgs.runCommand "limine-install.py" {} ''
      sed -e 's/+NixOS {group_name}/+finix {group_name}/' \
          -e 's/NixOS boot entries/finix boot entries/g' \
          -e '/specialisations = bootjson\[/a\    specialisations = {k: v for k, v in specialisations.items() if k != "vbios-maintenance"}' \
          -e "s|config_file += str(config('extraEntries'))|config_file += str(config('extraEntries')).replace(\"__LUINIT_SYSTEM__\", os.path.realpath(sys.argv[1]) if len(sys.argv) > 1 else \"\")|" \
          -e "/if config('secureBoot', 'enable'):/i\        if not config('efiRemovable'):\n            copy_file(dest_path, os.path.join(str(config('efiMountPoint')), 'EFI', 'BOOT', boot_file))" \
          ${flakeInputs.finix}/modules/programs/limine/limine-install.py > $out
    '';
    isExecutable = true;
    replacements = {
      python3 = pkgs.python3.withPackages (python-packages: [python-packages.psutil]);
      configPath = pkgs.writeText "limine-install.json" (builtins.toJSON {
        inherit
          (cfg)
          additionalFiles
          biosDevice
          biosSupport
          efiSupport
          enrollConfig
          extraEntries
          force
          partitionIndex
          settings
          validateChecksums
          secureBoot
          ;

        nixPath = config.services.nix-daemon.package;
        efiBootMgrPath = pkgs.efibootmgr;
        liminePath = cfg.package;
        efiMountPoint = config.boot.loader.efi.efiSysMountPoint;
        inherit (config) fileSystems;
        inherit (config.boot.loader.efi) canTouchEfiVariables;
        efiRemovable = cfg.efiInstallAsRemovable;
        maxGenerations =
          if cfg.maxGenerations == null
          then 0
          else cfg.maxGenerations;
        hostArchitecture = pkgs.stdenv.hostPlatform.parsed.cpu;
        fwupdEfiPath = config.services.fwupd.package or null;
      });
    };
  });

  finit.package = lib.mkForce luinitFinit;

  system.switch.inhibitors.luinit-wire-ver = luinitWireVer;

  environment = {
    etc."luinit/world".source = "${luinitWorld}/bin/luinit-world";
    systemPackages = [inputPackages.luin.luinit-ctl];
  };

  programs.limine = {
    enable = true;

    maxGenerations = 20;

    additionalFiles = {
      "EFI/luinos/kernel" = "${config.boot.kernelPackages.kernel}/bzImage";
      "EFI/luinos/initrd" = "${config.boot.initrd.package}/initrd";
    };

    extraEntries = ''
      /Finix golden
        protocol: linux
        comment: pinned fallback from the running system
        kernel_path: boot():/EFI/finix/kernels/golden/kernel
        cmdline: init=/nix/store/ralz7prz3545kixkfwag61ky42z1j8b9-finix-system/init nvidia-drm.modeset=1 nvidia-drm.fbdev=1 nvidia.NVreg_UsePageAttributeTable=1 nvidia.NVreg_EnableResizableBar=1 nvidia.NVreg_RegistryDwords=RmEnableAggressiveVblank=1 nvidia_modeset.disable_vrr_memclk_switch=1 nvidia.NVreg_TemporaryFilePath=/var/tmp amd_pstate=active mitigations=off console=tty0 panic=30 oops=panic softlockup_panic=1 hung_task_panic=1
        module_path: boot():/EFI/finix/kernels/golden/initrd

      /LuinOS (luinit)
        protocol: linux
        comment: y0usaf-desktop booted with luinit PID 1
        kernel_path: boot():/EFI/luinos/kernel
        cmdline: init=${inputPackages.luin.luinit-floor}/bin/luinit-floor luinit.world=${luinitWorld}/bin/luinit-world luinit.system=__LUINIT_SYSTEM__ ${lib.concatStringsSep " " config.boot.kernelParams}
        module_path: boot():/EFI/luinos/initrd
    '';

    settings = {
      timeout = 5;
      hash_mismatch_panic = true;
      editor_enabled = false;
    };
  };

  fileSystems = shared.fileSystems {
    rootSize = "4G";
    tmpSize = "16G";
    boot = {
      uuid = "31F2-1AE7";
      options = ["fmask=0077" "dmask=0077" "noatime"];
    };
    mounts = {
      "/nix" = btrfs "subvol=@nix";
      "/persist" = btrfs "subvol=@persist";
      "/home" = btrfs "subvol=@home";
      "/btrfs" = btrfs "subvolid=5";
      "/home/y0usaf/.local/share/Steam" = btrfs "subvol=@steam";
      "/home/y0usaf/dev" = btrfs "subvol=@dev";
      "/home/y0usaf/Pictures" = btrfs "subvol=@pictures";
      "/home/y0usaf/DCIM" = btrfs "subvol=@dcim";
      "/home/y0usaf/Music" = btrfs "subvol=@music";
    };
  };

  user = {
    appearance.dpi = 109;

    ui.tomoe.displays = {
      "DP-4" = {
        mode = [5120 1440];
        icc = "${pkgs.runCommand "ls49ag95.icc" {} "${lib.getExe' pkgs.colord "cd-create-profile"} -o $out ${./ls49ag95.iccprofile.xml}"}";
      };
      "HDMI-A-2" = {
        mode = [1920 1080 60];
        position = [5120 0];
      };
    };
  };
}
