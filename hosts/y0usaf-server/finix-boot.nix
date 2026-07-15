# Stage-3 bridge: keep NixOS's Limine generations and add the persistent
# Finix system beside them. The NixOS Limine entry has now been menu-booted
# cleanly; Finix becomes the default while NixOS remains the rescue entry.
{finixStaging, ...}: let
  finixSystem = finixStaging.serverPersistent.config.system.topLevel;
in {
  boot.loader.limine = {
    # extraConfig is prepended before NixOS's generated default_entry: 2;
    # Limine keeps the first global assignment, so this selects Finix after
    # the clean NixOS menu boot has been verified.
    extraConfig = "default_entry: Finix persistent";

    additionalFiles = {
      "finix/kernel" = "${finixSystem}/kernel";
      "finix/initrd" = "${finixSystem}/initrd";
    };

    extraEntries = ''
      /Finix persistent
        protocol: linux
        comment: Finix persistent server system
        kernel_path: boot():/limine/finix/kernel
        cmdline: init=${finixSystem}/init console=tty0 panic=30 oops=panic softlockup_panic=1 hung_task_panic=1
        module_path: boot():/limine/finix/initrd
    '';
  };
}
