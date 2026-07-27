# Boot ownership for y0usaf-desktop: finix owns /boot via the UPSTREAM
# programs.limine module (2026-07-27; replaces the custom single-Limine
# section writer — modules/finix/limine-entries.nix is deleted).
#
# Why the NOTES.md landmine no longer applies HERE: the warning was
# "upstream limine uses the same ESP paths as NixOS's module and prunes
# what it didn't write → destroys the NixOS rescue path". The NixOS
# generations were already stripped from limine.conf in the single-Limine
# era, and Windows boots via its own EFI entry (Boot0001), not Limine —
# nothing left on this ESP to destroy. The SERVER keeps the ESP island;
# this module stays OFF there (headless: the BootNext deadman ceremony
# still earns its keep).
#
# Effect: switch-to-configuration switch|boot runs
# providers.bootloader.installHook (limine-install.py), which renders
# /boot/limine/limine.conf from /nix/var/nix/profiles/system generations
# and installs + enrolls \efi\limine\BOOTX64.EFI. `nh os switch` then IS
# the complete day-2 flow: build → activate (stc test) → new profile
# generation → stc boot (installHook). Rollback = pick an older
# generation at the Limine menu, exactly the NixOS model.
{
  # limine-install.py reads boot.json (RFC-0125 org.nixos.bootspec.v1)
  # from every generation link; finix emits it when this is on.
  boot.bootspec.enable = true;

  # Let the installer create/update the "Limine" EFI entry (Boot0000,
  # already exists) — also guarantees the efivarfs mount.
  boot.loader.efi.canTouchEfiVariables = true;

  # Early AMD microcode: the island loaded amd-ucode.img as a separate
  # Limine module; limine-install.py has no ucode concept, so bake it
  # into the initrd instead (PR #103, in pin). LOAD-BEARING on this box:
  # BIOS ships 0x0a601206, every island boot updated early to 0x0a60120a.
  hardware.cpu.amd.updateMicrocode = true;

  programs.limine = {
    enable = true;
    # Keep the island era's tamper-evidence: the conf hash is enrolled
    # into BOOTX64.EFI and a mismatch panics. Secure Boot stays off in
    # firmware; flipping secureBoot.enable later pulls in upstream's
    # assertion set (enroll + validateChecksums + no editor) itself.

    enrollConfig = true;
    maxGenerations = 20;
    settings = {
      timeout = 5;
      hash_mismatch_panic = true;
      # default false; stated explicitly — the editor is an init=/bin/sh
      # root vector.
      editor_enabled = false;
    };
  };
}
