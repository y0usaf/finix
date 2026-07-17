# Menu bridge into the Finix ESP island: makes "Finix (island)" visible in
# the ordinary NixOS Limine menu (plain reboots land here — the island's
# own EFI entry Boot0005 sits LAST in BootOrder by design until promote).
#
# Chainloads the island's self-contained Limine (\EFI\finix\BOOTX64.EFI,
# app-adjacent limine.conf, default_entry: 1, timeout 3), so this entry
# always boots whatever slot `nix run .#finix-desktop-boot -- local install`
# staged last — no kernel/initrd copies to keep in sync, and the island's
# per-slot amd-ucode prepend applies unchanged.
#
# The island menu carries a "NixOS rescue (Limine)" chainload back; the
# loop is human-driven and harmless.
_: {
  boot.loader.limine.extraEntries = ''
    /Finix (island)
      protocol: efi
      comment: chainload the self-contained \EFI\finix island (latest staged slot)
      path: boot():/EFI/finix/BOOTX64.EFI
  '';
}
