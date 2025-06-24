###############################################################################
# MediaMTX Configuration
# WebRTC media server for streaming:
# - Enables WebRTC streaming server on port 4200
# - Configures public IP detection for external access
# - Sets up firewall rules for streaming
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  port = "4200";

  # Get all assigned local IPs for WebRTC configuration
  localips = builtins.concatLists (
    builtins.map (iface: builtins.map (addr: addr.address) iface.ipv4.addresses) (
      builtins.attrValues config.networking.interfaces
    )
  );

  # MediaMTX doesn't support IPv6 and fails if one is present, so filter for IPv4 only
  nameservers = config.networking.nameservers;
  isIPv4 = addr: builtins.match "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" addr != null;
  ipv4Nameservers = builtins.filter isIPv4 nameservers;

  # Get public IP dynamically using a simple approach
  getPublicIP = pkgs.writeShellScript "get-public-ip" ''
    ${pkgs.curl}/bin/curl -s https://api.ipify.org || echo "127.0.0.1"
  '';
in {
  config = {
    ###########################################################################
    # MediaMTX Service Configuration
    # WebRTC streaming server setup
    ###########################################################################
    services.mediamtx = {
      enable = true;
      settings = {
        # WebRTC Configuration
        webrtc = true;
        webrtcAddress = ":${port}";
        webrtcLocalUDPAddress = ":${port}";
        webrtcAdditionalHosts =
          # Add local IPs and nameservers
          ipv4Nameservers ++ localips;

        # Allow publishing to all paths - enables streaming from any source
        paths = {
          all_others = {
            # Allow all sources to publish
            publishUser = "";
            publishPass = "";
            publishIps = [];

            # Allow all to read
            readUser = "";
            readPass = "";
            readIps = [];
          };
        };

        # API settings for management
        api = true;
        apiAddress = "127.0.0.1:9997";
      };
    };

    ###########################################################################
    # Firewall Configuration
    # Open required ports for WebRTC streaming
    ###########################################################################
    networking.firewall = {
      allowedTCPPorts = [
        (lib.toInt port) # WebRTC signaling
        9997 # API port (localhost only)
      ];
      allowedUDPPorts = [
        (lib.toInt port) # WebRTC media
      ];
    };

    ###########################################################################
    # System Activation Script
    # Update MediaMTX config with public IP at boot
    ###########################################################################
    system.activationScripts.mediamtx-public-ip = {
      text = ''
        # Get public IP and update MediaMTX configuration
        PUBLIC_IP=$(${getPublicIP})
        CONFIG_FILE="/etc/mediamtx.yaml"

        if [ -f "$CONFIG_FILE" ] && [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "127.0.0.1" ]; then
          echo "Updating MediaMTX with public IP: $PUBLIC_IP"

          # Create a temporary config with the public IP added
          ${pkgs.yq-go}/bin/yq eval ".webrtcAdditionalHosts += [\"$PUBLIC_IP\"]" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
          mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

          # Restart mediamtx if it's running
          if ${pkgs.systemd}/bin/systemctl is-active mediamtx.service >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl restart mediamtx.service
          fi
        else
          echo "Could not determine public IP or config file not found"
        fi
      '';
    };

    ###########################################################################
    # Environment Configuration
    # Ensure mediamtx is available in system PATH
    ###########################################################################
    environment.systemPackages = with pkgs; [
      mediamtx
    ];
  };
}
