# Phase-2d: NixOS parity sweep gating promote. Upstream finix modules
# where they exist (bluetooth/polkit/rtkit), server-proven ports where
# they don't (tailscaled), hand-rolls where nothing exists (zram).
# Sources mirrored from the NixOS universe:
#   modules/core/hardware/bluetooth.nix   (bluez settings)
#   modules/core/services/tailscale/*     (rescue-path semantics!)
#   modules/desktop/apps/obs.nix          (v4l2loopback virtual cam)
#   modules/gaming/core.nix               (gamemode group)
#   hosts/y0usaf-desktop/hardware-configuration.nix (zramSwap 50% zstd)
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  # These upstream modules are NOT in mkFinixSystem's baseline (udev/dbus/
  # seatd et al are wired into finixSystem itself; these three are opt-in).
  imports = with flakeInputs.finix.nixosModules; [bluetooth polkit rtkit];

  # ── bluetooth: upstream module; settings parity with the NixOS side.
  # powerOnBoot=true translates to Policy.AutoEnable. blueman/bluetuith
  # arrive via the packages bridge; bluetoothd is the part that must run.
  services.bluetooth = {
    enable = true;
    settings = {
      General = {
        ControllerMode = "dual";
        FastConnectable = true;
      };
      Policy.AutoEnable = true;
    };
  };

  # ── polkit + rtkit: polkit unlocks privileged desktop actions (and is
  # rtkit's authorization backend); rtkit restores the RT scheduling the
  # NixOS pipewire unit got via systemd (Nice -20 / SCHED_RR) — pipewire's
  # module-rt negotiates with rtkit-daemon at runtime.
  services.polkit = {
    enable = true;
    adminIdentities = ["unix-user:y0usaf"];
  };
  services.rtkit.enable = true;

  # ── tailscale: no upstream module; server-proven stanza. State dir
  # /var/lib/tailscale is already a /persist bind via the impermanence
  # replay, so the desktop keeps its tailnet identity (and the `ssh
  # rescue` path stays valid from the other side).
  boot.kernelModules = ["tun" "v4l2loopback" "zram"];
  finit.services.tailscaled = {
    description = "tailscale mesh VPN daemon";
    command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
    path = [pkgs.iproute2 pkgs.iptables pkgs.procps];
    conditions = ["net/lo/up"];
    log = true;
  };
  finit.tasks.tailscale-ssh = {
    description = "assert tailscale SSH rescue path";
    conditions = ["net/lo/up"];
    command = pkgs.writeShellScript "tailscale-ssh-assert" ''
      set -u
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.tailscale]}
      for _ in $(seq 1 60); do
        if tailscale --socket=/run/tailscale/tailscaled.sock set --ssh 2>/dev/null; then
          echo "tailscale-ssh: RunSSH asserted"
          exit 0
        fi
        sleep 2
      done
      echo "tailscale-ssh: could not assert --ssh" >&2
      exit 1
    '';
    log = true;
  };

  # ── OBS virtual camera (NixOS obs.nix parity).
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  environment.etc."modprobe.d/v4l2loopback.conf".text = ''
    options v4l2loopback exclusive_caps=1
  '';

  # ── zram swap: zramSwap.enable { 50%, zstd } has no upstream module —
  # literal port of what the NixOS option does at runtime.
  finit.tasks.zram-swap = {
    description = "zram swap (50% RAM, zstd)";
    command = pkgs.writeShellScript "zram-swap" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.gnugrep pkgs.gawk pkgs.kmod]}
      modprobe zram || true
      grep -q zram /proc/swaps && exit 0
      mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
      dev=$(zramctl --find --size "$((mem_kb / 2))K" --algorithm zstd)
      mkswap "$dev" >/dev/null
      swapon -p 100 "$dev"
      echo "zram-swap: $dev active"
    '';
    log = true;
  };

  # ── gaming: gamemoded is dbus-activated per session; it only needs its
  # group to exist for the renice policy. gamescope/gamemode/steam
  # binaries + steam-hardware udev rules come via the bridge.
  users.groups.gamemode = {};
  users.users.y0usaf.extraGroups = ["gamemode"];
}
