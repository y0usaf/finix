{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.pxe-server;
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options.services.pxe-server = {
    enable = mkEnableOption "PXE netboot server for NixOS installation";

    interface = mkOption {
      type = types.str;
      default = "eth0";
      description = "Network interface to bind services to";
    };

    dhcpRange = mkOption {
      type = types.str;
      default = "192.168.1.100,192.168.1.150";
      description = "DHCP IP range for PXE clients";
    };

    serverIP = mkOption {
      type = types.str;
      default = "192.168.1.1";
      description = "Server IP address";
    };
  };

  config = mkIf cfg.enable {
    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/pxe 0755 root root -"
      "d /var/lib/pxe/tftp 0755 root root -"
      "d /var/lib/pxe/http 0755 root root -"
    ];

    # Services configuration
    services = {
      # TFTP server for PXE boot files
      atftpd = {
        enable = true;
        root = "/var/lib/pxe/tftp";
      };

      # DHCP server with PXE options (SECURITY RISK - see warning below)
      dhcpd4 = {
        enable = true;
        interfaces = [cfg.interface];
        extraConfig = ''
          option space pxelinux;
          option pxelinux.magic code 208 = string;
          option pxelinux.configfile code 209 = text;
          option pxelinux.pathprefix code 210 = text;
          option pxelinux.reboottime code 211 = unsigned integer 32;
          option architecture-type code 93 = unsigned integer 16;

          subnet 192.168.1.0 netmask 255.255.255.0 {
            range ${cfg.dhcpRange};
            option routers ${cfg.serverIP};
            option domain-name-servers 8.8.8.8;

            class "pxeclients" {
              match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
              next-server ${cfg.serverIP};
              filename "pxelinux.0";
            }
          }
        '';
      };

      # HTTP server for NixOS ISO
      nginx = {
        enable = true;
        virtualHosts."pxe-server" = {
          listen = [
            {
              addr = cfg.serverIP;
              port = 80;
            }
          ];
          root = "/var/lib/pxe/http";
          locations."/" = {
            extraConfig = "autoindex on;";
          };
        };
      };
    };

    # Restrictive firewall - only allow PXE services
    networking.firewall = {
      allowedTCPPorts = [80]; # HTTP for ISO download
      allowedUDPPorts = [67 69]; # DHCP and TFTP
      # Consider adding interface-specific rules:
      # interfaces.${cfg.interface}.allowedTCPPorts = [80];
      # interfaces.${cfg.interface}.allowedUDPPorts = [67 69];
    };

    # Auto-setup PXE files
    systemd.services.pxe-setup = {
      description = "Setup PXE boot files";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "pxe-setup" ''
          #!${pkgs.bash}/bin/bash
          set -e

          TFTP_ROOT="/var/lib/pxe/tftp"
          HTTP_ROOT="/var/lib/pxe/http"

          # Download syslinux
          if [[ ! -f "$TFTP_ROOT/pxelinux.0" ]]; then
            ${pkgs.wget}/bin/wget -P /tmp https://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
            ${pkgs.gnutar}/bin/tar -xf /tmp/syslinux-6.03.tar.xz -C /tmp
            cp /tmp/syslinux-6.03/bios/core/pxelinux.0 "$TFTP_ROOT/"
            cp /tmp/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 "$TFTP_ROOT/"
            cp /tmp/syslinux-6.03/bios/com32/menu/vesamenu.c32 "$TFTP_ROOT/"
            cp /tmp/syslinux-6.03/bios/com32/libutil/libutil.c32 "$TFTP_ROOT/"
            rm -rf /tmp/syslinux-6.03*
          fi

          # Create boot menu
          mkdir -p "$TFTP_ROOT/pxelinux.cfg"
          cat > "$TFTP_ROOT/pxelinux.cfg/default" << 'EOF'
          DEFAULT vesamenu.c32
          PROMPT 0
          TIMEOUT 300

          LABEL nixos
            MENU LABEL Install NixOS
            KERNEL nixos/bzImage
            APPEND initrd=nixos/initrd.xz root=live:http://${cfg.serverIP}/nixos.iso boot=live
          EOF

          # Download NixOS
          mkdir -p "$TFTP_ROOT/nixos"
          if [[ ! -f "$HTTP_ROOT/nixos.iso" ]]; then
            ${pkgs.wget}/bin/wget -O "$HTTP_ROOT/nixos.iso" https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

            # Extract kernel/initrd
            mkdir -p /tmp/iso
            ${pkgs.util-linux}/bin/mount -o loop "$HTTP_ROOT/nixos.iso" /tmp/iso
            cp /tmp/iso/boot/bzImage "$TFTP_ROOT/nixos/"
            cp /tmp/iso/boot/initrd.xz "$TFTP_ROOT/nixos/"
            ${pkgs.util-linux}/bin/umount /tmp/iso
            rmdir /tmp/iso
          fi
        '';
      };
    };
  };
}
