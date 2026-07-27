# Stage-3 bridge: keep NixOS's Limine generations and add the persistent
# Finix system beside them. With the ESP island (modules/finix/default.nix,
# `nix run .#finix-server-boot`) this menu entry is now the *tertiary* way
# into Finix - the canonical boot path is the \EFI\finix island + "Finix"
# EFI entry; this entry remains for a human at the console and only tracks
# the generation baked at the last NixOS deploy.
{
  pkgs,
  finixStaging,
  ...
}: let
  finixSystem = finixStaging.serverPersistent.config.system.topLevel;
in {
  boot.loader.limine = {
    additionalFiles = {
      "finix/kernel" = "${finixSystem}/kernel";
      # Early microcode - direct boots must not run raw BIOS ucode (0x1a);
      # see 2026-07-15 freeze in modules/finix/NOTES.md. Listed as first module.
      "finix/ucode.img" = "${pkgs.microcode-intel}/intel-ucode.img";
      "finix/initrd" = "${finixSystem}/initrd";
    };

    extraEntries = ''
      /Finix persistent
        protocol: linux
        comment: Finix persistent server system
        kernel_path: boot():/limine/finix/kernel
        cmdline: init=${finixSystem}/init console=tty0 panic=30 oops=panic softlockup_panic=1 hung_task_panic=1
        module_path: boot():/limine/finix/ucode.img
        module_path: boot():/limine/finix/initrd
    '';
  };
}
