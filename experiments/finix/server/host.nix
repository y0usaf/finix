# Bare-metal finix host wrapper for y0usaf-server.
# Unlike the VM, this:
#   - keeps sshd strict (PAM on, StrictModes on)
#   - reads the y0usaf password hash from /persist/secrets/password-hashes/y0usaf
#   - enables blocky / btrbk / acme via finix.server.extras
#   - uses limine on the existing EFI partition
#   - re-uses the same service module as the VM (`server-vm/common.nix`)
inputs: {
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware.nix
    (import ./impermanence.nix {
      # Same physical disk as current NixOS install. Use the raw device node in
      # stage 1 to avoid the mdevd/blkid race around /dev/disk/by-uuid.
      device = "/dev/sda2";
      includeMediaSubvols = true;
    })
    ./extras.nix
    (import ../server-vm/common.nix inputs)
  ];

  networking.hostName = "y0usaf-server";
  time.timeZone = "America/Toronto";

  # Read the real password hash from the persist partition instead of
  # hard-coding one. The VM keeps a literal `password = ...` guarded by
  # `isVm`; here we override with the file path.
  users.users.y0usaf.passwordFile = lib.mkForce "/persist/secrets/password-hashes/y0usaf";

  # UKI workaround: boot stage 2 via `$systemConfig/activate` (a real shell
  # script) rather than `$systemConfig/init` (a relative symlink). The stock
  # switch_root helper's `access("/sysroot$init", X_OK)` check trips on the
  # symlink path on this host, even though the target exists. When `activate`
  # runs as PID 1 we finish activation, then `exec finit` in-place.
  system.activation.scripts.zzzzExecFinit = {
    text = ''
      if [ "$$" -eq 1 ]; then
        echo "activation: exec finit as PID 1"
        # Preserve argv[0] as $systemConfig/init so finix-setup derives the
        # correct top-level system path from /proc/self/cmdline.
        exec -a "$systemConfig/init" ${config.finit.package}/bin/finit
      fi
    '';
  };

  # Diagnostic: if DHCP fails, bring the primary NIC up with a static IP so
  # the box stays reachable. Tries DHCP first (via the existing dhcpcd
  # service), then falls back after 45s if no lease. Only needed for the
  # trial period; can be disabled once we trust the config.
  finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = pkgs.writeShellScript "net-fallback" ''
      set -eu
      # Give dhcpcd a fair shot.
      for _ in $(seq 1 45); do
        if ${pkgs.iproute2}/bin/ip -4 addr show enp1s0 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
          echo "net-fallback: dhcp succeeded, nothing to do"
          exit 0
        fi
        sleep 1
      done
      echo "net-fallback: DHCP timed out, configuring static"
      ${pkgs.iproute2}/bin/ip link set enp1s0 up || true
      ${pkgs.iproute2}/bin/ip addr add 192.168.2.67/24 dev enp1s0 || true
      ${pkgs.iproute2}/bin/ip route add default via 192.168.2.1 dev enp1s0 || true
      printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
    '';
    conditions = ["net/lo/up"];
    log = true;
  };

  # Diagnostic: on each boot, copy the kernel ring buffer + finit state
  # to /persist/finix-boot.log so we can post-mortem a broken boot from
  # NixOS after a power cycle. Runs at runlevel 2 end ("everything
  # started or gave up").
  finit.tasks.boot-breadcrumb = {
    description = "persist kernel log + initctl status";
    command = pkgs.writeShellScript "boot-breadcrumb" ''
      set -eu
      outdir=/persist/finix-boot
      ${pkgs.coreutils}/bin/mkdir -p "$outdir"
      ts=$(${pkgs.coreutils}/bin/date -u +%Y-%m-%dT%H-%M-%SZ)
      {
        echo "==== $(${pkgs.coreutils}/bin/date -u) boot ===="
        echo '---- kernel cmdline ----'
        ${pkgs.coreutils}/bin/cat /proc/cmdline
        echo '---- dmesg ----'
        ${pkgs.util-linux}/bin/dmesg
        echo '---- initctl status ----'
        /usr/bin/env initctl status 2>&1 || true
        echo '---- ip addr ----'
        ${pkgs.iproute2}/bin/ip addr
        echo '---- routes ----'
        ${pkgs.iproute2}/bin/ip route
        echo '---- ss ----'
        ${pkgs.iproute2}/bin/ss -ltn 2>&1 || true
        echo '---- mounts ----'
        ${pkgs.util-linux}/bin/findmnt 2>&1 || true
      } > "$outdir/$ts.log" 2>&1 || true
      # Keep last 20 logs.
      cd "$outdir"
      ls -1t *.log 2>/dev/null | ${pkgs.coreutils}/bin/tail -n +21 | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
    '';
    conditions = ["net/lo/up"];
    log = true;
  };

  # Trial-boot debugging: stage 2 appears to hang after starting
  # `suid-sgid-wrappers` and `coldplug`. Disable both temporarily so we can
  # see how far the system gets without them.
  finit.tasks.suid-sgid-wrappers.enable = lib.mkForce false;
  finit.run.coldplug.enable = lib.mkForce false;

  # Tailscale: drop an authkey file at /persist/secrets/tailscale/authkey and
  # run `tailscale up` once per boot.
  finit.tasks.tailscale-up = {
    description = "tailscale authkey login";
    command = pkgs.writeShellScript "tailscale-up" ''
      set -euo pipefail
      authkey_file=/persist/secrets/tailscale/authkey
      if [ ! -s "$authkey_file" ]; then
        echo "tailscale-up: $authkey_file missing, skipping"
        exit 0
      fi
      until ${pkgs.tailscale}/bin/tailscale \
        --socket /run/tailscale/tailscaled.sock status >/dev/null 2>&1; do
        sleep 1
      done
      ${pkgs.tailscale}/bin/tailscale \
        --socket /run/tailscale/tailscaled.sock up \
        --authkey "$(cat "$authkey_file")" \
        --hostname ${lib.escapeShellArg config.networking.hostName} \
        --ssh \
        --accept-routes
    '';
    conditions = ["service/tailscaled/running"];
    log = true;
  };

  # Turn on extras.
  finix.server.extras = {
    blocky.enable = true;
    btrbk.enable = true;
    bayt.enable = false; # stub — flip on when ported
    acme = {
      enable = false; # flip on + set domains once DNS points at this box
      email = "";
      domains = [];
    };
  };

  # Firewall parity with current NixOS host.
  services.nftables = {
    enable = lib.mkForce true;
    configFile = lib.mkForce (pkgs.writeText "nftables.conf" ''
      flush ruleset

      table inet filter {
        chain input {
          type filter hook input priority 0;
          policy drop;

          iifname lo accept
          ct state established,related accept
          ip protocol icmp accept
          ip6 nexthdr ipv6-icmp accept

          tcp dport { 22, 53, 80, 443, 2222, 3000, 5678, 8384, 22000 } accept
          udp dport { 53, 4200, 21027, 22000, 41641 } accept
        }
        chain forward {
          type filter hook forward priority 0;
          policy drop;
        }
        chain output {
          type filter hook output priority 0;
          policy accept;
        }
      }
    '');
  };
}
