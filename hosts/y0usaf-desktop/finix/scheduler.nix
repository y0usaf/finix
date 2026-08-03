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
#
# scx_lavd's compat layer hard-requires debugfs (panics with "No debugfs
# mount found" otherwise, exit 101 — observed on first rollout). finix does
# not mount debugfs by default (same as efivarfs: the consumer mounts it),
# so the pre hook mounts it idempotently before every start. /sys/kernel/debug
# lives on the fresh root tmpfs each boot, so the mount must happen per-start,
# which pre guarantees. A mount failure here = service failure = finit marks
# it crashed (recoverable, CFS unchanged) — same safety envelope as before.
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

    pre = "${pkgs.writeShellScript "mount-debugfs" ''
      ${pkgs.util-linux}/bin/mountpoint -q /sys/kernel/debug \
        || ${pkgs.util-linux}/bin/mount -t debugfs debugfs /sys/kernel/debug
    ''}";
  };
}