# scx_lavd sched_ext CPU scheduler — port of the NixOS
# modules/core/services/scx.nix that DRIFT-AUDIT.md flagged UNPORTED.
# sched_ext (CONFIG_SCHED_CLASS_EXT, upstream since 6.12) swaps the CPU
# scheduler for a BPF-loaded one; scx_lavd (Latency-criticality Aware Virtual
# Deadline) targets interactive/gaming latency. The desktop already runs
# linuxPackages_latest (persistent.nix), which ships sched_ext + BTF.
#
# Finix has no services.scx module (that is NixOS's systemd wrapper); the
# finix-native equivalent is a finit service running the scheduler binary.
# Killing the process reverts to CFS; the kernel watchdog also reverts on
# failure (sched-ext docs). finit restarts a crashed service (default 10
# retries, 2-5s backoff) — same resilience as systemd Restart=on-failure.
{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.scx.rustscheds];

  finit.services.scx = {
    description = "scx_lavd sched_ext CPU scheduler";
    command = "${pkgs.scx.rustscheds}/bin/scx_lavd";
    log = true;
  };
}
