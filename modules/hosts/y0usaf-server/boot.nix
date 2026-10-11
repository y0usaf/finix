{
  config,
  pkgs,
  ...
}: {
  boot.loader.script = {
    enable = true;
    installHook = pkgs.writeShellApplication {
      name = "finix-server-install-bootloader";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux pkgs.efibootmgr pkgs.jq];
      text = ''
        system="$(readlink -f "''${1:?system path required}")"
        esp=${config.boot.loader.efi.efiSysMountPoint}
        mountpoint -q "$esp"
        target="$esp/EFI/finix"
        slot="$(basename "$system")"
        mkdir -p "$target/kernels/$slot"
        stage="$(mktemp -d "$target/.install.XXXXXX")"
        trap 'rm -rf "$stage"' EXIT
        cp "$system/kernel" "$stage/kernel"
        cat ${pkgs.microcode-intel}/intel-ucode.img "$system/initrd" > "$stage/initrd"
        mv "$stage/kernel" "$target/kernels/$slot/kernel"
        mv "$stage/initrd" "$target/kernels/$slot/initrd"
        cmdline="$(jq -er '.["org.nixos.bootspec.v1"] | "init=" + .init + " " + (.kernelParams | join(" "))' "$system/boot.json")"
        {
          printf 'timeout: 3\ndefault_entry: 1\n\n/Finix\n  protocol: linux\n'
          printf '  kernel_path: boot():/EFI/finix/kernels/%s/kernel\n' "$slot"
          printf '  cmdline: %s\n' "$cmdline"
          printf '  module_path: boot():/EFI/finix/kernels/%s/initrd\n' "$slot"
        } > "$stage/limine.conf"
        cp ${pkgs.limine}/share/limine/BOOTX64.EFI "$stage/BOOTX64.EFI"
        mv "$stage/limine.conf" "$target/limine.conf"
        mv "$stage/BOOTX64.EFI" "$target/BOOTX64.EFI"
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
