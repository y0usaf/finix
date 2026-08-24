# Boot assessment for the ESP-island flow (incident #3 hardening): prove the
# running system really is the island's current slot before anyone runs
# `finix-server-boot promote`. Mismatch = the reboot fell back to an old slot
# and promotion must NOT happen.
{pkgs, ...}: {
  finit.tasks.boot-health = {
    description = "verify booted system matches island current slot";
    conditions = ["net/lo/up"];
    command = pkgs.writeShellScript "boot-health" ''
      set -u
      export PATH=${pkgs.lib.makeBinPath [pkgs.coreutils pkgs.gnused]}
      island=/boot/EFI/finix
      state_dir=/var/lib/boot-health
      mkdir -p "$state_dir"
      cur=$(sed -n 's/^current=//p' "$island/slots")
      staged=$(cat "$island/kernels/$cur/system")
      booted=$(readlink /run/booted-system)
      if [ "$booted" = "$staged" ]; then
        printf 'slot=%s\nsystem=%s\ndate=%s\n' "$cur" "$booted" "$(date -Iseconds)" > "$state_dir/last-good"
        echo "boot-health: OK - booted system is island slot $cur"
        exit 0
      fi
      printf 'slot=%s\nstaged=%s\nbooted=%s\ndate=%s\n' "$cur" "$staged" "$booted" "$(date -Iseconds)" > "$state_dir/last-bad"
      echo "boot-health: MISMATCH - booted $booted but island current slot $cur stages $staged" >&2
      exit 1
    '';
    log = true;
  };
}
