{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.services.mediamtx.enable {
    services.mediamtx.settings = {
      webrtc = true;
      webrtcAddress = ":4200";
      webrtcLocalUDPAddress = ":4200";
      paths = {
        all_others = {};
      };
    };

    systemd.services.mediamtx.serviceConfig.EnvironmentFile = "/etc/mediamtx.env";

    systemd.services.mediamtx-update-ip = {
      description = "Update MediaMTX public IP";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "update-mediamtx-env" ''
          PUBLIC_IP=$(${pkgs.curl}/bin/curl -s https://api.ipify.org || echo "127.0.0.1")
          ENV_FILE="/etc/mediamtx.env"

          if [ -n "$PUBLIC_IP" ] && [ "$PUBLIC_IP" != "127.0.0.1" ]; then
            echo "MTX_WEBRTCADDITIONALHOSTS=$PUBLIC_IP" > "$ENV_FILE"
          else
            echo "# No public IP available" > "$ENV_FILE"
          fi
        '';
      };
      before = ["mediamtx.service"];
      wantedBy = ["multi-user.target"];
    };

    networking.firewall = {
      allowedTCPPorts = [4200];
      allowedUDPPorts = [4200];
    };

    environment.systemPackages = [
      pkgs.mediamtx
    ];
  };
}
