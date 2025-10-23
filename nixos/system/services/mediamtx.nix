{
  lib,
  pkgs,
  ...
}: let
  port = "4200";

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
        webrtc = true;
        webrtcAddress = ":${port}";
        webrtcLocalUDPAddress = ":${port}";
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
