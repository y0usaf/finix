# Guard rails that make headless finix kexec trials safe (see modules/finix/NOTES.md at the
# repo root). Also gives NixOS itself hang self-recovery via the hardware
# watchdog. Must be switched in on the server before running
# `nix run .#finix-server-trial`.
{pkgs, ...}: {
  # Exactly ONE watchdog driver, always: with both intel_oc_wdt and iTCO_wdt
  # loaded, watchdog0/watchdog1 ordering is nondeterministic across boots and
  # across NixOS<->finix transitions, so the armed device and the petted
  # device can diverge (observed: stray reset ~2min after returning from a
  # trial). intel_oc_wdt is the one systemd runs with on this box.
  boot.kernelModules = ["intel_oc_wdt"];
  boot.blacklistedKernelModules = ["iTCO_wdt"];

  systemd.settings.Manager = {
    # Pet the watchdog while NixOS runs: a hard hang of NixOS itself now
    # self-recovers with a reset instead of requiring a power cycle.
    RuntimeWatchdogSec = "1min";
    # Cover hangs during reboot.
    RebootWatchdogSec = "3min";
    # The critical one: arm the watchdog *before* the kexec jump into finix.
    # If finix hangs anywhere before its keepalive service starts petting,
    # the board resets and the untouched bootloader boots NixOS.
    KExecWatchdogSec = "2min";
  };

  environment.systemPackages = [
    pkgs.kexec-tools
    pkgs.efibootmgr
  ];
}
