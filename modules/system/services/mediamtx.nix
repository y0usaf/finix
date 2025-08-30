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

  publicIPScript = pkgs.writeShellScript "update-mediamtx-env" ''
    PUBLIC_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org || echo "127.0.0.1")
    ENV_FILE="/etc/mediamtx.env"

    if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "127.0.0.1" ]; then
      echo "MTX_WEBRTCADDITIONALHOSTS=$PUBLIC_IP" > "$ENV_FILE"
    else
      echo "# No public IP available" > "$ENV_FILE"
    fi
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
        webrtcAdditionalHosts = ipv4Nameservers ++ localips;
        paths = {
          all_others = {};
        };
      };
    };

    systemd.services.mediamtx.serviceConfig.EnvironmentFile = "/etc/mediamtx.env";

    systemd.services.mediamtx-update-ip = {
      description = "Update MediaMTX public IP";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = publicIPScript;
      };
      before = ["mediamtx.service"];
      wantedBy = ["multi-user.target"];
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

    environment.systemPackages = [
      pkgs.mediamtx
    ];
  };
}
