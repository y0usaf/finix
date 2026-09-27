{
  lib,
  pkgs,
  ...
}: {
  users = {
    users.mediamtx = {
      isSystemUser = true;
      group = "mediamtx";
    };
    groups.mediamtx = {};
  };

  finit = {
    tasks.mediamtx-env = {
      description = "update mediamtx public IP env";
      conditions = ["net/lo/up"];
      command = pkgs.writeShellScript "mediamtx-env" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.curl]}
        ip="$(curl -s --max-time 15 https://api.ipify.org || true)"
        if [ -n "$ip" ]; then
          echo "MTX_WEBRTCADDITIONALHOSTS=$ip" > /run/mediamtx.env
        else
          echo "# no public IP available" > /run/mediamtx.env
        fi
      '';
      log = true;
    };

    services.mediamtx = {
      description = "mediamtx media server";
      user = "mediamtx";
      group = "mediamtx";
      command = "${pkgs.writeShellScript "mediamtx-start" ''
        if [ -r /run/mediamtx.env ]; then
          set -a
          . /run/mediamtx.env
          set +a
        fi
        exec ${pkgs.mediamtx}/bin/mediamtx ${(pkgs.formats.yaml {}).generate "mediamtx.yaml" {
          webrtc = true;
          webrtcAddress = ":4200";
          webrtcLocalUDPAddress = ":4200";
          paths.all_others = {};
        }}
      ''}";
      conditions = [
        "net/lo/up"
        "task/mediamtx-env/success"
      ];
      log = true;
    };
  };
}
