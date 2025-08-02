{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.pxe-server-secure;
  inherit (lib) mkEnableOption mkOption mkIf types;
in {
  options.services.pxe-server-secure = {
    enable = mkEnableOption "Secure PXE server (TFTP/HTTP only, no DHCP)";

    interface = mkOption {
      type = types.str;
      default = "eno1";
      description = "Network interface to bind services to";
    };

    serverIP = mkOption {
      type = types.str;
      default = "192.168.2.28";
      description = "Server IP address";
    };

    allowedSubnet = mkOption {
      type = types.str;
      default = "192.168.2.0/24";
      description = "Subnet allowed to access PXE services";
    };
  };

  config = mkIf cfg.enable {
    # Create directories
    systemd.tmpfiles.rules = [
      "d /var/lib/pxe 0755 root root -"
      "d /var/lib/pxe/tftp 0755 root root -"
      "d /var/lib/pxe/http 0755 root root -"
    ];

    # TFTP server (read-only, specific interface)
    services.atftpd = {
      enable = true;
      root = "/var/lib/pxe/tftp";
      extraOptions = [
        "--bind-address=${cfg.serverIP}"
        "--no-fork"
        "--logfile=/var/log/atftpd.log"
      ];
    };

    # HTTP server (restricted access)
    services.nginx = {
      enable = true;
      virtualHosts."pxe-server" = {
        listen = [
          {
            addr = cfg.serverIP;
            port = 8080;
          }
        ];
        root = "/var/lib/pxe/http";
        locations."/" = {
          extraConfig = ''
            autoindex on;
            allow ${cfg.allowedSubnet};
            deny all;
          '';
        };
      };
    };

    # Strict firewall - interface-specific rules
    networking.firewall = {
      interfaces.${cfg.interface} = {
        allowedTCPPorts = [8080]; # HTTP on non-standard port
        allowedUDPPorts = [69]; # TFTP only
      };
      # Explicitly deny these services on other interfaces
      allowedTCPPorts = [];
      allowedUDPPorts = [];
    };

    # Setup script
    systemd.services.pxe-setup-secure = {
      description = "Setup secure PXE files";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeScript "pxe-setup-secure" ''
          #!${pkgs.bash}/bin/bash
          set -e

          TFTP_ROOT="/var/lib/pxe/tftp"
          HTTP_ROOT="/var/lib/pxe/http"

          # Setup syslinux
          if [[ ! -f "$TFTP_ROOT/pxelinux.0" ]]; then
            ${pkgs.wget}/bin/wget -P /tmp https://kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz
            ${pkgs.gnutar}/bin/tar -xf /tmp/syslinux-6.03.tar.xz -C /tmp
            cp /tmp/syslinux-6.03/bios/core/pxelinux.0 "$TFTP_ROOT/"
            cp /tmp/syslinux-6.03/bios/com32/elflink/ldlinux/ldlinux.c32 "$TFTP_ROOT/"
            cp /tmp/syslinux-6.03/bios/com32/menu/vesamenu.c32 "$TFTP_ROOT/"
            rm -rf /tmp/syslinux-6.03*
          fi

          # Boot config
          mkdir -p "$TFTP_ROOT/pxelinux.cfg"
          cat > "$TFTP_ROOT/pxelinux.cfg/default" << 'EOF'
          DEFAULT vesamenu.c32
          PROMPT 0
          TIMEOUT 300
          MENU TITLE NixOS PXE Boot

          LABEL nixos
            MENU LABEL Install NixOS
            KERNEL nixos/bzImage
            APPEND initrd=nixos/initrd.xz root=live:http://${cfg.serverIP}:8080/nixos.iso boot=live
          EOF

          # Download NixOS
          mkdir -p "$TFTP_ROOT/nixos"
          if [[ ! -f "$HTTP_ROOT/nixos.iso" ]]; then
            echo "Downloading NixOS ISO..."
            ${pkgs.wget}/bin/wget -O "$HTTP_ROOT/nixos.iso" \
              https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

            # Extract boot files
            mkdir -p /tmp/iso
            ${pkgs.util-linux}/bin/mount -o loop "$HTTP_ROOT/nixos.iso" /tmp/iso
            cp /tmp/iso/boot/bzImage "$TFTP_ROOT/nixos/"
            cp /tmp/iso/boot/initrd.xz "$TFTP_ROOT/nixos/"
            ${pkgs.util-linux}/bin/umount /tmp/iso
            rmdir /tmp/iso
            echo "PXE setup complete"
          fi
        '';
      };
    };

    # Optional: Create README with manual DHCP config
    environment.etc."pxe-manual-setup.txt".text = ''
      MANUAL PXE SETUP REQUIRED:

      This secure PXE server does NOT run DHCP to avoid network conflicts.

      Configure your existing DHCP server (router) with these options:
      - DHCP Option 66 (TFTP Server): ${cfg.serverIP}
      - DHCP Option 67 (Boot Filename): pxelinux.0

      Or configure the target machine's BIOS/UEFI to use:
      - Boot Server IP: ${cfg.serverIP}
      - Boot File: pxelinux.0

      Services running:
      - TFTP: ${cfg.serverIP}:69
      - HTTP: ${cfg.serverIP}:8080
    '';
  };
}
