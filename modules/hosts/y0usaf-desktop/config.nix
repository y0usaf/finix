{
  lib,
  pkgs,
  ...
}: {
  networking.hostName = "y0usaf-desktop";

  finix.persistence.allowlist.directories = [
    "/root"
    "/var/lib/btrbk"
    "/var/lib/sbctl"
  ];

  environment.etc."finix-stage2".text = "desktop-phase2.4\n";

  services = {
    nftables.configFile = (import ../shared.nix {inherit lib pkgs;}).nftables "finix-desktop.nft" {
      tailscaleComment = "tailnet peers are authenticated; primary sshd:2222 path";
      input = ''
        udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

        iifname "eno1" tcp dport 2222 accept comment "sshd LAN fallback: independent of tailscale being up. Wired NIC only - never wlp96s0"

        tcp dport { 25565, 27015, 27036 } accept comment "minecraft host; steam dedicatedServer; steam remotePlay"
        udp dport { 21027, 27015, 41641 } accept comment "syncthing LAN discovery; steam dedicatedServer; tailscale direct path (parity.nix --port=41641)"
        udp dport 27031-27036 accept comment "steam remotePlay"
        tcp dport 2234 accept comment "nicotine-plus Soulseek"
        udp dport 2234 accept comment "nicotine-plus Soulseek"

        iifname "eno1" tcp dport 9757 accept comment "mado for the Steam Frame"
        iifname "eno1" udp dport 9757 accept comment "mado for the Steam Frame"
      '';
    };
    sysklogd.extraConfig = "*.* @192.168.2.66:514";
  };

  finit.services.nix-daemon.cgroup.settings."cpu.max" = 2400000;

  users.users.y0usaf.uid = 1001;
  users.users.root.passwordFile = "/persist/secrets/password-hashes/root";

  finit.tasks.net-fallback = {
    description = "static IP fallback if DHCP fails";
    command = "${pkgs.writeShellScript "desktop-net-fallback" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.iproute2 pkgs.gnugrep]}

      find_iface() {
        for dev in /sys/class/net/en* /sys/class/net/eth*; do
          [ -e "$dev" ] || continue
          basename "$dev"
          return 0
        done
        return 1
      }

      for _ in $(seq 1 45); do
        if ${pkgs.iproute2}/bin/ip -4 addr show scope global 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -q 'inet '; then
          exit 0
        fi
        sleep 1
      done

      iface="$(find_iface)" || exit 1
      ${pkgs.iproute2}/bin/ip link set "$iface" up || true
      ${pkgs.iproute2}/bin/ip addr replace 192.168.2.28/24 dev "$iface" || true
      ${pkgs.iproute2}/bin/ip route replace default via 192.168.2.1 dev "$iface" || true
      printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf || true
    ''}";
    conditions = ["net/lo/up"];
    log = true;
  };

  user = {
    appearance = {
      termFontSize = 16;
      hyprcursorSize = 36;
    };

    ui.tomoe.bar.modules = ["media" "cpu" "memory" "time" "date" "gpu" "vram" "frame"];
    ui.tomoe.bar.style = "gap";

    gaming = {
      p4g.enable = true;
      solo-leveling-arise.enable = true;
      aethermancer.enable = true;
      elden-ring.enable = true;
      proton.enable = true;
      runelite.enable = true;
      aniimo = {
        enable = true;
        mods = ["camera" "movement" "rewards"];
      };
    };

    tools."3d-printing".enable = true;
  };
}
