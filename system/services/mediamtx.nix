{
  config,
  lib,
  pkgs,
  ...
}: let
  port = "4200";
  localips = builtins.concatLists (
    builtins.map (iface: builtins.map (addr: addr.address) iface.ipv4.addresses) (
      builtins.attrValues config.networking.interfaces
    )
  );
  inherit (config.networking) nameservers;
  isIPv4 = addr: builtins.match "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$" addr != null;
  ipv4Nameservers = builtins.filter isIPv4 nameservers;
  getPublicIP = pkgs.writeShellScript "get-public-ip" ''
    ${pkgs.curl}/bin/curl -s https://api.ipify.org || echo "127.0.0.1"
  '';
in {
  config = {
    services.mediamtx = {
      enable = true;
      settings = {
        api = true;
        apiAddress = "127.0.0.1:9997";
        rtsp = true;
        rtspAddress = ":8554";
        rtmp = true;
        rtmpAddress = ":1935";
        hls = true;
        hlsAddress = ":8080";
        hlsAllowOrigin = "*";
        webrtc = true;
        webrtcAddress = ":${port}";
        webrtcLocalUDPAddress = ":${port}";
        webrtcAdditionalHosts =
          ipv4Nameservers ++ localips;
        paths = {
          all_others = {};
        };
      };
    };
    networking.firewall = {
      allowedTCPPorts = [
        (lib.toInt port)
        8554
        1935
        8080
        9997
      ];
      allowedUDPPorts = [
        (lib.toInt port)
        8000
        8001
      ];
    };
    system.activationScripts.mediamtx-public-ip = {
      text = ''
        PUBLIC_IP=$(${getPublicIP})
        CONFIG_FILE="/etc/mediamtx.yaml"
        if [ -f "$CONFIG_FILE" ] && [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "127.0.0.1" ]; then
          echo "Updating MediaMTX with public IP: $PUBLIC_IP"
          ${pkgs.yq-go}/bin/yq eval ".webrtcAdditionalHosts += [\"$PUBLIC_IP\"]" "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
          mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
          if ${pkgs.systemd}/bin/systemctl is-active mediamtx.service >/dev/null 2>&1; then
            ${pkgs.systemd}/bin/systemctl restart mediamtx.service
          fi
        else
          echo "Could not determine public IP or config file not found"
        fi
      '';
    };
    environment.systemPackages = with pkgs; [
      mediamtx
    ];
  };
}
