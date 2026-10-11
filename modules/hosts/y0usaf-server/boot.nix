{
  config,
  pkgs,
  ...
}: let
  maxGenerations = 5;
in {
  boot.loader.script = {
    enable = true;
    installHook = pkgs.writeShellApplication {
      name = "finix-server-install-bootloader";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.jq pkgs.gawk];
      text = ''
        system="$(readlink -f "''${1:?system path required}")"
        esp=${config.boot.loader.efi.efiSysMountPoint}
        mountpoint -q "$esp"
        target="$esp/EFI/finix"
        mkdir -p "$target/kernels"
        stage="$(mktemp -d "$target/.install.XXXXXX")"
        trap 'rm -rf "$stage"' EXIT
        printf 'timeout: 3\ndefault_entry: 1\n' > "$stage/limine.conf"
        write_entry() {
          local generation="$1" label="$2" slot cmdline
          slot="$(basename "$generation")"
          mkdir -p "$target/kernels/$slot"
          cp "$generation/kernel" "$stage/kernel"
          cat ${pkgs.microcode-intel}/intel-ucode.img "$generation/initrd" > "$stage/initrd"
          mv "$stage/kernel" "$target/kernels/$slot/kernel"
          mv "$stage/initrd" "$target/kernels/$slot/initrd"
          cmdline="$(jq -er '.["org.nixos.bootspec.v1"] | "init=" + .init + " " + (.kernelParams | join(" "))' "$generation/boot.json")"
          {
            printf '\n/Finix %s\n  protocol: linux\n' "$label"
            printf '  kernel_path: boot():/EFI/finix/kernels/%s/kernel\n' "$slot"
            printf '  cmdline: %s\n' "$cmdline"
            printf '  module_path: boot():/EFI/finix/kernels/%s/initrd\n' "$slot"
          } >> "$stage/limine.conf"
        }
        write_entry "$system" "(current)"
        generation_list="$("$system/sw/bin/nix-env" --list-generations -p /nix/var/nix/profiles/system)"
        generation_list="$(printf '%s\n' "$generation_list" | sort -nr | awk '{print $1}')"
        mapfile -t generations <<< "$generation_list"
        count=1
        for generation in "''${generations[@]}"; do
          [ "$count" -lt ${toString maxGenerations} ] || break
          previous="$(readlink -e "/nix/var/nix/profiles/system-$generation-link")"
          [ "$previous" != "$system" ] || continue
          write_entry "$previous" "generation $generation"
          count=$((count + 1))
        done
        cp ${pkgs.limine}/share/limine/BOOTX64.EFI "$stage/BOOTX64.EFI"
        mv "$stage/limine.conf" "$target/limine.conf"
        mv "$stage/BOOTX64.EFI" "$target/BOOTX64.EFI"
        sync -f "$esp"
        retained="$(cat "$target/limine.conf")"
        for old in "$target"/kernels/*; do
          [ -d "$old" ] || continue
          slot="$(basename "$old")"
          if [[ "$retained" != *"kernel_path: boot():/EFI/finix/kernels/$slot/kernel"* ]]; then
            rm -rf -- "$old"
          fi
        done
        mountpoint -q /sys/firmware/efi/efivars || mount -t efivarfs efivarfs /sys/firmware/efi/efivars
        entries="$(efibootmgr)"
        if [[ ! "$entries" =~ Boot[[:xdigit:]]{4}[*]?[[:space:]]Finix[[:space:]] ]]; then
          partition="$(findmnt -nro SOURCE --target "$esp")"
          partition="$(readlink -f "$partition")"
          disk="/dev/$(lsblk -ndo PKNAME "$partition")"
          number="$(cat "/sys/class/block/$(basename "$partition")/partition")"
          efibootmgr -c -d "$disk" -p "$number" -L Finix -l '\EFI\finix\BOOTX64.EFI'
        fi
        sync -f "$esp"
      '';
    } + "/bin/finix-server-install-bootloader";
  };
}
