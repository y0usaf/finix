{
  lib,
  pkgs,
  ...
}: let
  diskUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";

  subvol = name: opts: {
    device = "/dev/disk/by-uuid/${diskUuid}";
    fsType = "btrfs";
    options = ["subvol=${name}"] ++ opts;
    neededForBoot = true;
  };

  persistBind = dir: {
    device = "/persist${dir}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };
in {
  fileSystems = {
    "/home" = subvol "@home" ["compress=zstd" "noatime"];
    "/home/y0usaf/Music" = subvol "@music" [];
    "/home/y0usaf/DCIM" = subvol "@dcim" [];
    "/home/y0usaf/Pictures" = subvol "@pictures" [];
    "/btrfs" = {
      device = "/dev/disk/by-uuid/${diskUuid}";
      fsType = "btrfs";
      options = ["subvolid=5"];
      neededForBoot = true;
    };

    "/var/lib/forgejo" = persistBind "/var/lib/forgejo";
    "/var/lib/postgresql" = persistBind "/var/lib/postgresql";
    "/var/lib/tailscale" = persistBind "/var/lib/tailscale";
    "/var/lib/btrbk" = persistBind "/var/lib/btrbk";
  };

  boot.kernelModules = [
    "tun"
    "nf_tables"
  ];

  services = {
    openssh.settings = {
      Port = [2200];
    };
    nftables = {
      enable = true;
      configFile = pkgs.writeText "finix-server.nft" ''
        flush ruleset

        table inet filter {
          chain input {
            type filter hook input priority filter; policy drop;

            iifname "lo" accept
            iifname "tailscale0" accept comment "tailnet peers are authenticated"
            ct state established,related accept
            ct state invalid drop
            meta l4proto { icmp, ipv6-icmp } accept

            udp sport 67 udp dport 68 accept comment "dhcpcd lease traffic"

            iifname "eth0" tcp dport 2200 accept comment "sshd LAN fallback: this box has no console and no IPMI, so the tailnet must not be its only way in"

            tcp dport { 80, 443, 2222, 3000, 22000, 4200, 8787 } accept comment "2222 = forgejo ssh, NOT sshd (that is the eth0 rule); 8787 attic cache (LAN builds, tailnet too slow)"
            udp dport { 21027, 22000, 4200, 41641 } accept
          }
          chain forward {
            type filter hook forward priority filter; policy drop;
          }
        }
      '';
    };
    postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      authentication = ''
        local all all peer
      '';
    };
    cron.enable = true;
  };

  networking.hosts = {
    "100.105.204.116" = ["forgejo" "syncthing-server"];
    "100.90.54.18" = ["syncthing-desktop"];
  };

  users = {
    users = {
      forgejo = {
        isSystemUser = true;
        uid = 993;
        group = "forgejo";
        home = "/var/lib/forgejo";
      };
      mediamtx = {
        isSystemUser = true;
        group = "mediamtx";
      };
      nginx = {
        isSystemUser = true;
        group = "nginx";
      };
    };
    groups = {
      forgejo.gid = 989;
      mediamtx = {};
      nginx = {};
    };
  };

  providers.scheduler = {
    backend = "cron";
    tasks.btrbk-snapshots = {
      interval = "daily";
      command = "${lib.getExe pkgs.btrbk} -q -c ${pkgs.writeText "btrbk.conf" ''
        timestamp_format long
        snapshot_preserve_min 2d
        snapshot_preserve 7d 4w

        volume /btrfs
          snapshot_dir _snapshots
          subvolume @dcim
          subvolume @music
      ''} run";
    };
  };

  finit = {
    tmpfiles.rules = [
      "d /run/tailscale 0755 root root"
      "d /run/nginx 0755 root root"
    ];

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
          echo "tailscale-ssh: tailscaled socket never came up" >&2
          exit 1
        '';
        log = true;
      };

      mediamtx-env = {
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
    };

    services = {
      forgejo = {
        description = "forgejo git hosting";
        user = "forgejo";
        group = "forgejo";
        command = "${pkgs.writeShellScript "forgejo-start" ''
          for _ in $(seq 1 60); do
            ${pkgs.postgresql_16}/bin/pg_isready -q -h /run/postgresql && break
            sleep 1
          done
          ${pkgs.postgresql_16}/bin/pg_isready -q -h /run/postgresql || exit 1
          exec ${pkgs.forgejo-lts}/bin/forgejo web
        ''}";
        path = [
          pkgs.forgejo-lts
          pkgs.git
          pkgs.gnupg
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnugrep
          pkgs.gnused
          pkgs.bash
        ];
        environment = {
          HOME = "/var/lib/forgejo";
          FORGEJO_WORK_DIR = "/var/lib/forgejo";
          FORGEJO_CUSTOM = "/var/lib/forgejo/custom";
          FORGEJO__SECURITY__SECRET_KEY__FILE = "/var/lib/forgejo/custom/conf/secret_key";
          FORGEJO__SECURITY__INTERNAL_TOKEN__FILE = "/var/lib/forgejo/custom/conf/internal_token";
          FORGEJO__SERVER__LFS_JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/lfs_jwt_secret";
          FORGEJO__OAUTH2__JWT_SECRET__FILE = "/var/lib/forgejo/custom/conf/oauth2_jwt_secret";
        };
        conditions = [
          "net/lo/up"
          "service/syslogd/ready"
        ];
        log = true;
      };

      mediamtx = {
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

      tailscaled = {
        description = "tailscale mesh VPN daemon";
        command = "${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641";
        path = [
          pkgs.iproute2
          pkgs.iptables
          pkgs.procps
        ];
        conditions = ["net/lo/up"];
        log = true;
      };

      syncthing = {
        description = "syncthing file sync (y0usaf)";
        user = "y0usaf";
        command = "${pkgs.syncthing}/bin/syncthing --config=/home/y0usaf/.config/syncthing --data=/home/y0usaf/.config/syncthing --gui-address=127.0.0.1:8384 --no-browser";
        environment.HOME = "/home/y0usaf";
        conditions = ["net/lo/up"];
        log = true;
      };

      nginx = {
        description = "nginx reverse proxy (syncthing GUI)";
        command = "${pkgs.nginx}/bin/nginx -c ${pkgs.writeText "nginx.conf" ''
          daemon off;
          worker_processes 1;
          pid /run/nginx/nginx.pid;

          events {}

          http {
            access_log off;
            proxy_temp_path /run/nginx/proxy_temp;
            client_body_temp_path /run/nginx/client_body_temp;
            fastcgi_temp_path /run/nginx/fastcgi_temp;
            uwsgi_temp_path /run/nginx/uwsgi_temp;
            scgi_temp_path /run/nginx/scgi_temp;

            map $http_upgrade $connection_upgrade {
              default upgrade;
              ""      close;
            }

            server {
              listen 80;
              server_name syncthing-server;

              location / {
                proxy_pass http://127.0.0.1:8384;
                proxy_http_version 1.1;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_read_timeout 600s;
                proxy_send_timeout 600s;
              }
            }
          }
        ''} -e stderr";
        conditions = ["net/lo/up"];
        log = true;
      };
    };
  };

  environment.systemPackages = [
    pkgs.tailscale
    pkgs.btrbk
    pkgs.postgresql_16
  ];
}
