{
  flakeInputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;
  stockNvflashSha256 = "bc36918546a749650a1a28cfd990a506a531b77529b57a7f119ad214563bc7e7";
  vbiosBackup = pkgs.writeShellApplication {
    name = "vbios-backup";
    runtimeInputs = with pkgs; [
      coreutils
      diffutils
      findutils
      gnugrep
      kmod
    ];
    text = ''
      set -euo pipefail

      if [[ $EUID -ne 0 ]]; then
        echo "error: run with sudo" >&2
        exit 1
      fi
      if [[ $# -ne 2 ]]; then
        echo "usage: sudo vbios-backup /path/to/stock/nvflash /path/to/empty-output-directory" >&2
        exit 2
      fi

      nvflash=$1
      output=$2
      gpu=/sys/bus/pci/devices/0000:01:00.0

      [[ -x $nvflash ]] || {
        echo "error: stock NVFlash is not executable: $nvflash" >&2
        exit 1
      }
      actual_nvflash_hash=$(sha256sum "$nvflash" | cut -d ' ' -f 1)
      [[ $actual_nvflash_hash == ${stockNvflashSha256} ]] || {
        echo "error: unsupported stock NVFlash SHA-256: $actual_nvflash_hash" >&2
        echo "expected: ${stockNvflashSha256}" >&2
        exit 1
      }

      if grep -Eq '^(nvidia|nvidia_drm|nvidia_modeset|nvidia_uvm|nouveau) ' /proc/modules; then
        echo "error: an NVIDIA/Nouveau module is loaded; refusing to continue" >&2
        exit 1
      fi
      [[ ! -e $gpu/driver ]] || {
        echo "error: RTX 4090 still has a bound kernel driver; refusing to continue" >&2
        exit 1
      }
      [[ $(<"$gpu/vendor") == 0x10de ]] \
        && [[ $(<"$gpu/device") == 0x2684 ]] \
        && [[ $(<"$gpu/subsystem_vendor") == 0x10de ]] \
        && [[ $(<"$gpu/subsystem_device") == 0x16f4 ]] || {
        echo "error: expected RTX 4090 FE at 0000:01:00.0 was not found" >&2
        exit 1
      }
      [[ -L /sys/bus/pci/devices/0000:6a:00.0/driver ]] \
        && [[ $(basename "$(readlink /sys/bus/pci/devices/0000:6a:00.0/driver)") == amdgpu ]] || {
        echo "error: AMD recovery display is not bound to amdgpu" >&2
        exit 1
      }

      mkdir -p "$output"
      [[ -z $(find "$output" -mindepth 1 -maxdepth 1 -print -quit) ]] || {
        echo "error: output directory must be empty: $output" >&2
        exit 1
      }

      umask 077
      first="$output/factory-full-1.rom"
      second="$output/factory-full-2.rom"
      "$nvflash" -i 0 --save "$first"
      "$nvflash" -i 0 --save "$second"

      cmp "$first" "$second"
      [[ $(stat -c %s "$first") -gt 150528 ]] || {
        echo "error: dump is not larger than the incomplete PCI ROM image" >&2
        exit 1
      }
      sha256sum "$first" "$second" | tee "$output/SHA256SUMS"
      sync "$output"

      echo "verified: two byte-identical full VBIOS reads"
      echo "copy this directory to independent storage before any write test"
    '';
  };
in {
  specialisation.vbios-maintenance = {
    inheritParentConfig = true;
    configuration = {
      system.nixos.tags = ["vbios-maintenance"];
      systemd.defaultUnit = "multi-user.target";

      hardware = {
        nvidia = {
          enable = lib.mkForce false;
          management.enable = lib.mkForce false;
        };
        amdgpu = {
          enable = lib.mkForce true;
          initrd.enable = true;
        };
        display.outputs = lib.mkForce {};
      };

      boot = {
        blacklistedKernelModules = [
          "nvidia"
          "nvidia_drm"
          "nvidia_modeset"
          "nvidia_uvm"
          "nouveau"
        ];
        kernelParams = [
          "module_blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm,nouveau"
        ];
      };

      environment = {
        systemPackages = [
          vbiosBackup
          flakeInputs.nvflashk-linux.packages.${system}.default
          pkgs.pciutils
          pkgs.tmux
        ];
        etc."vbios-maintenance/README".text = ''
          VBIOS maintenance boot

          This specialisation boots to multi-user.target, enables the AMD iGPU,
          and blocks NVIDIA/Nouveau kernel modules. It performs no firmware write.

          Full backup:
            sudo vbios-backup /path/to/stock/nvflash /path/to/empty-output-directory

          The helper accepts only stock Linux NVFlash SHA-256:
            ${stockNvflashSha256}
        '';
      };
    };
  };
}
