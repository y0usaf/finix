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
}: let
  # Native now: user.programs.asryx arrives via compat-import of
  # modules/desktop/apps/asryx.nix (same options, this module universe).
  asryxCfg = config.user.programs.asryx;
in {
  # These upstream modules are NOT in mkFinixSystem's baseline (udev/dbus/
  # seatd et al are wired into finixSystem itself; the rest are opt-in).
  imports = with flakeInputs.finix.nixosModules; [bluetooth polkit rtkit udisks2 upower];

  # ── bluetooth: upstream module; settings parity with the NixOS side.
  # powerOnBoot=true translates to Policy.AutoEnable. blueman/bluetuith
  # arrive via the packages bridge; bluetoothd is the part that must run.
  services = {
    bluetooth = {
      enable = true;
      settings = {
        General = {
          ControllerMode = "dual";
          FastConnectable = true;
        };
        Policy.AutoEnable = true;
      };
    };
    polkit = {
      enable = true;
      adminIdentities = ["unix-user:y0usaf"];
    };
    rtkit.enable = true;

    # Bridge era got these via NixOS's own service modules; finix's ship
    # their udev rules + dbus activation themselves.
    upower.enable = true;
    udisks2.enable = true;

    # Waydroid (testing, sandbox ~/dev/sandbox/tft-waydroid): ship the
    # id.waydro.Container dbus policy + service file so the system bus lets
    # root own the container-manager name. Container itself is started
    # manually (sudo waydroid container start), not as a finit service.
    dbus.packages = [pkgs.waydroid-nftables];

    # ntsync: Wine's sync-on-NT-semaphores driver (reduces esync/fsync
    # overhead for games under the bundled Wine/Proton). Rule shipped as a
    # package (portable NixOS + finix) via services.udev.packages, never
    # extraRules — parity with upstream finix uinput rules.
    udev.packages = [
      (pkgs.writeTextFile {
        name = "ntsync-udev";
        destination = "/etc/udev/rules.d/70-ntsync.rules";
        text = ''KERNEL=="ntsync", MODE="0644"'';
      })
    ];
  };

  # ddcutil monitor control: finix's i2c module ships the rules; NixOS-side
  # this rode hardware.i2c.enable (modules/core/hardware/i2c.nix).
  hardware.i2c.enable = true;

  # ── polkit + rtkit: polkit unlocks privileged desktop actions (and is
  # rtkit's authorization backend); rtkit restores the RT scheduling the
  # NixOS pipewire unit got via systemd (Nice -20 / SCHED_RR) — pipewire's
  # module-rt negotiates with rtkit-daemon at runtime.

  # ── tailscale: no upstream module; server-proven stanza. State dir
  # /var/lib/tailscale is already a /persist bind via the impermanence
  # replay, so the desktop keeps its tailnet identity (and the `ssh
  # rescue` path stays valid from the other side).
  # uinput: asryx autofill (dotool types the transcript; udev rule granting
  # the input group access rides the packages-bridge as extra-udev-rules).
  boot.kernelModules = ["tun" "v4l2loopback" "zram" "uinput" "ntsync"];
  finit = {
    services.tailscaled = {
      description = "tailscale mesh VPN daemon";
      command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
      path = [pkgs.iproute2 pkgs.iptables pkgs.procps];
      conditions = ["net/lo/up"];
      log = true;
    };
    tasks = {
      tailscale-ssh = {
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
      zram-swap = {
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
      x11-socket-dir = {
        description = "fix /tmp mode + create X11 socket dirs";
        command = pkgs.writeShellScript "x11-socket-dir" ''
          export PATH=${lib.makeBinPath [pkgs.coreutils]}
          chmod 1777 /tmp
          install -d -m 1777 /tmp/.X11-unix /tmp/.ICE-unix
        '';
        log = true;
      };
      # Page-cache warm for the asryx model: on NixOS a systemd oneshot
      # (asryx.nix) does this; under finit it needs its own task. cat is
      # enough — evictable page cache, no mlock, no daemon.
      asryx-warm = lib.mkIf (asryxCfg.enable && asryxCfg.warm) {
        description = "warm asryx whisper model into page cache";
        command = pkgs.writeShellScript "asryx-warm" ''
          export PATH=${lib.makeBinPath [pkgs.coreutils]}
          cat ${asryxCfg.modelPath} ${asryxCfg.vadPath} > /dev/null
        '';
        log = true;
      };
    };
  };

  # ── OBS virtual camera (NixOS obs.nix parity).
  boot.extraModulePackages = [config.boot.kernelPackages.v4l2loopback];
  environment = {
    etc."modprobe.d/v4l2loopback.conf".text = ''
      options v4l2loopback exclusive_caps=1
    '';
    etc."ssl/certs/ca-certificates.crt".source = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
  };

  # finix's upstream xdg modules own these links: portal adds applications
  # + portal definitions, icons adds icons + pixmaps, and mime adds shared
  # MIME data (replacing the former hand-rolled list).
  xdg.icons.enable = true;
  xdg.mime.enable = true;

  # ── zram swap: zramSwap.enable { 50%, zstd } has no upstream module —
  # literal port of what the NixOS option does at runtime.

  # ── gaming: gamemoded is dbus-activated per session; it only needs its
  # group to exist for the renice policy. gamescope/gamemode/steam
  # binaries + steam-hardware udev rules come via the bridge.
  # input: dotool opens /dev/uinput (asryx autofill); rule 99-local.rules
  # (bridged) grants the input group rw on the uinput node.
  # bluetooth (bluetoothd), lp (CUPS/printing), dialout (serial/tty devices)
  # — restored from the deleted modules/desktop/user-groups.nix.
  users.groups = {
    gamemode = {};
    bluetooth = {};
    lp = {};
    dialout = {};
  };
  users.users.y0usaf.extraGroups = ["gamemode" "input" "bluetooth" "lp" "dialout"];

  # ── X11 socket dir + /tmp mode: systemd-tmpfiles owned both on NixOS.
  # Xwayland (hence xwayland-satellite, hence Steam) refuses to create
  # /tmp/.X11-unix as non-root — sticky root-owned world-writable, the
  # X11 convention. UPSTREAM GAP: finix activation mkdirs /tmp under
  # umask 0022 → 0755 (NixOS: 1777), so anything non-root writing tmp
  # files (browsers, sandboxes, our own tooling) fails until fixed.

  # ── CA bundle under the Debian name: finix renders ca-bundle.crt only;
  # Steam's ubuntu-runtime tooling (and other FHS-expectation software)
  # hardcodes ca-certificates.crt — its absence surfaced as the updater's
  # opaque "http error 0" TLS failure.

  # ── XDG dirs parity: finix's upstream xdg.portal/icons/mime modules now
  # own the links (including portal definitions and .desktop discovery),
  # preserving the old applications/icons/pixmaps/mime set while fixing the
  # missing portal scan path; this closes the #160 pathsToLink workaround.
}
