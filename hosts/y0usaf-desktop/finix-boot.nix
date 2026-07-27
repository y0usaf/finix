# RETIRED 2026-07-27: the "/Finix (island)" chainload entry. The desktop no
# longer has a second Limine — modules/finix/limine-entries.nix (finix-desktop-boot)
# manages finix slots as direct entries inside THIS Limine's limine.conf
# (marked FINIX-MANAGED section), with NixOS generations as rescue below.
#
# Kept as a no-op module because hostDir is imported wholesale; deleting the
# file works too, but the note survives a rebuild either way: do NOT re-add
# extraEntries chainloading \EFI\finix — that bootloader is gone.
#
# Reminder of the tradeoff: a NixOS rebuild regenerates limine.conf and
# wipes the FINIX-MANAGED section → re-run
#   nix run .#finix-desktop-boot -- local install
# from the finix boot to restore the finix default.
# Ownership ladder (2026-07-28, modules/finix/limine-entries.nix): `local adopt` =
# driver owns BOOTX64.EFI too (every render re-enrolls + re-signs);
# `local retire-nixos` = strip NixOS generations for good. A NixOS rebuild
# still clobbers binary+conf until the store purge — recovery: `local install`.
_: {
}
