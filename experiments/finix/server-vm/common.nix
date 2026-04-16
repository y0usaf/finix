inputs: {
  config,
  lib,
  pkgs,
  ...
}: let
  isTestVm = config ? testing && config.testing ? enable && config.testing.enable;

  dockerConfig = (pkgs.formats.json {}).generate "docker-daemon.json" {
    "data-root" = "/var/lib/docker";
    group = "docker";
    hosts = ["unix:///run/docker.sock"];
    iptables = false;
    "storage-driver" = "vfs";
    "exec-opts" = ["native.cgroupdriver=cgroupfs"];
  };

  mediamtxConfig = (pkgs.formats.yaml {}).generate "mediamtx.yaml" {
    webrtc = true;
    webrtcAddress = ":4200";
    webrtcLocalUDPAddress = ":4200";
    paths.all_others = {};
  };

  nftablesConfig = pkgs.writeText "nftables.conf" ''
    flush ruleset

    table inet filter {
      chain input {
        type filter hook input priority 0;
        policy drop;

        iifname lo accept
        ct state established,related accept
        ip protocol icmp accept
        ip6 nexthdr ipv6-icmp accept

        tcp dport { 22, 80, 443, 2222, 3000, 5678, 22000, 8384, 4200 } accept
        udp dport { 21027, 22000, 4200, 41641 } accept
      }

      chain forward {
        type filter hook forward priority 0;
        policy drop;
      }

      chain output {
        type filter hook output priority 0;
        policy accept;
      }
    }
  '';

  nginxConfig = pkgs.writeText "nginx.conf" ''
    user nginx nginx;
    worker_processes 1;
    pid /run/nginx/nginx.pid;

    events {}

    http {
      include ${pkgs.nginx}/conf/mime.types;
      default_type application/octet-stream;
      access_log /dev/stdout;
      error_log stderr info;
      sendfile on;

      client_body_temp_path /var/lib/nginx/client_temp;
      proxy_temp_path /var/lib/nginx/proxy_temp;
      fastcgi_temp_path /var/lib/nginx/fastcgi_temp;
      uwsgi_temp_path /var/lib/nginx/uwsgi_temp;
      scgi_temp_path /var/lib/nginx/scgi_temp;

      server {
        listen 80 default_server;
        server_name syncthing-server;

        location / {
          proxy_pass http://127.0.0.1:8384;
          proxy_http_version 1.1;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
        }
      }
    }
  '';

  dockerStart = pkgs.writeShellScript "dockerd-start" ''
    exec ${pkgs.docker}/bin/dockerd --config-file=/etc/docker/daemon.json
  '';

  tailscaledStart = pkgs.writeShellScript "tailscaled-start" ''
    exec ${pkgs.tailscale}/bin/tailscaled \
      --state=/var/lib/tailscale/tailscaled.state \
      --socket=/run/tailscale/tailscaled.sock \
      --port=41641
  '';

  syncthingStart = pkgs.writeShellScript "syncthing-start" ''
    exec ${pkgs.syncthing}/bin/syncthing \
      --no-browser \
      --gui-address=127.0.0.1:8384 \
      --config=/home/y0usaf/.config/syncthing \
      --data=/home/y0usaf/.local/state/syncthing
  '';

  syncthingDevices = [
    {
      deviceID = "KII4S2Y-KWA6M4K-MCQAUOO-C6PMX4L-V5JVDPW-HHZF52D-HP57BNH-EKCCZQC";
      name = "desktop";
    }
    {
      deviceID = "EAHAPON-XKBJVGI-44SGTXR-WU6BF5U-WZKHJXS-7QNTBHQ-D4ICOVA-I346HQ7";
      name = "laptop";
    }
    {
      deviceID = "GY3T3SL-3JOOX3I-2SE72PF-V6ZSTIE-QI4EIYK-OBL6IDV-4IWLDDG-VM2ATAG";
      name = "server";
    }
    {
      autoAcceptFolders = true;
      compression = "never";
      deviceID = "JYAIN4T-MXQYDAP-2M6CSKX-KKRYVJC-5GMSRYP-LSZRRRV-QSOWY7W-YNQGOAC";
      name = "phone";
    }
  ];

  syncthingFolders = [
    {
      id = "bv79n-fh4kx";
      label = "Tokens";
      path = "/home/y0usaf/Tokens";
      type = "receiveonly";
      devices = map (device: {deviceId = device.deviceID;}) syncthingDevices;
    }
    {
      id = "oty33-aq3dt";
      label = "Music";
      path = "/home/y0usaf/Music";
      type = "receiveonly";
      devices = map (device: {deviceId = device.deviceID;}) (
        builtins.filter (device: builtins.elem device.name ["desktop" "server" "phone"]) syncthingDevices
      );
    }
    {
      id = "ti9yk-zu3xs";
      label = "DCIM";
      path = "/home/y0usaf/DCIM";
      type = "receiveonly";
      devices = map (device: {deviceId = device.deviceID;}) (
        builtins.filter (device: builtins.elem device.name ["desktop" "server" "phone"]) syncthingDevices
      );
    }
    {
      id = "zbxzv-35v4e";
      label = "Pictures";
      path = "/home/y0usaf/Pictures";
      type = "receiveonly";
      devices = map (device: {deviceId = device.deviceID;}) (
        builtins.filter (device: builtins.elem device.name ["desktop" "server" "phone"]) syncthingDevices
      );
    }
  ];

  syncthingSetup = pkgs.writeShellScript "syncthing-setup" ''
        set -euo pipefail

        api_key_file=/home/y0usaf/.config/syncthing/api-key
        headers_file=/home/y0usaf/.config/syncthing/api-headers

        while ! test -s /home/y0usaf/.config/syncthing/config.xml; do
          sleep 1
        done

        while ! ${pkgs.libxml2}/bin/xmllint --xpath 'string(configuration/gui/apikey)' /home/y0usaf/.config/syncthing/config.xml > "$api_key_file"; do
          sleep 1
        done

        printf 'X-API-Key: ' > "$headers_file"
        cat "$api_key_file" >> "$headers_file"

        api() {
          local method="$1"
          local path="$2"
          local payload="''${3-}"

          if [ -n "$payload" ]; then
            ${pkgs.curl}/bin/curl -fsS -H "@$headers_file" -H 'Content-Type: application/json' -X "$method" --data "$payload" "http://127.0.0.1:8384$path"
          else
            ${pkgs.curl}/bin/curl -fsS -H "@$headers_file" -X "$method" "http://127.0.0.1:8384$path"
          fi
        }

        until ${pkgs.curl}/bin/curl -fsS http://127.0.0.1:8384/rest/noauth/health >/dev/null; do
          sleep 1
        done

    ${lib.concatMapStringsSep "\n" (device: "    api POST /rest/config/devices ${lib.escapeShellArg (builtins.toJSON device)} >/dev/null") syncthingDevices}

    ${lib.concatMapStringsSep "\n" (folder: "    api POST /rest/config/folders ${lib.escapeShellArg (builtins.toJSON folder)} >/dev/null") syncthingFolders}
  '';

  postgresStart = pkgs.writeShellScript "postgres-start" ''
    exec ${pkgs.postgresql}/bin/postgres -D /var/lib/postgresql/data -k /run/postgresql -c listen_addresses=127.0.0.1
  '';

  postgresInit = pkgs.writeShellScript "postgres-init" ''
        set -euo pipefail

        if ! test -e /var/lib/postgresql/data/PG_VERSION; then
          ${pkgs.coreutils}/bin/mkdir -p /var/lib/postgresql/data /run/postgresql
          ${pkgs.postgresql}/bin/initdb -U postgres -D /var/lib/postgresql/data
          ${pkgs.coreutils}/bin/cat >> /var/lib/postgresql/data/postgresql.conf <<EOF
    unix_socket_directories = '/run/postgresql'
    listen_addresses = '127.0.0.1'
    EOF
          ${pkgs.coreutils}/bin/cat > /var/lib/postgresql/data/pg_hba.conf <<EOF
    local all all trust
    host all all 127.0.0.1/32 trust
    host all all ::1/128 trust
    EOF
        fi
  '';

  postgresSetup = pkgs.writeShellScript "postgres-setup" ''
    set -euo pipefail

    export PGHOST=/run/postgresql

    until ${pkgs.postgresql}/bin/psql -d postgres -tAc 'SELECT 1' >/dev/null 2>&1; do
      sleep 1
    done

    if ! ${pkgs.postgresql}/bin/psql -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='forgejo'" | ${pkgs.gnugrep}/bin/grep -q 1; then
      ${pkgs.postgresql}/bin/psql -d postgres -c 'CREATE ROLE forgejo LOGIN'
    fi

    if ! ${pkgs.postgresql}/bin/psql -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='forgejo'" | ${pkgs.gnugrep}/bin/grep -q 1; then
      ${pkgs.postgresql}/bin/psql -d postgres -c 'CREATE DATABASE forgejo OWNER forgejo'
    fi
  '';

  forgejoSetup = pkgs.writeShellScript "forgejo-setup" ''
        set -euo pipefail

        secret_dir=/var/lib/forgejo/custom/conf
        mkdir -p "$secret_dir"

        ensure_secret() {
          local name="$1"
          local file="$2"
          if ! test -s "$file"; then
            ${pkgs.forgejo}/bin/forgejo generate secret "$name" > "$file"
            chmod 0600 "$file"
          fi
        }

        ensure_secret SECRET_KEY "$secret_dir/secret_key"
        ensure_secret INTERNAL_TOKEN "$secret_dir/internal_token"
        ensure_secret JWT_SECRET "$secret_dir/oauth2_jwt_secret"
        ensure_secret LFS_JWT_SECRET "$secret_dir/lfs_jwt_secret"

        cat > "$secret_dir/app.ini" <<EOF
    [DEFAULT]
    APP_NAME = Forgejo
    RUN_MODE = prod
    RUN_USER = forgejo
    WORK_PATH = /var/lib/forgejo

    [database]
    DB_TYPE = postgres
    HOST = /run/postgresql
    NAME = forgejo
    USER = forgejo
    SSL_MODE = disable

    [repository]
    ROOT = /var/lib/forgejo/repositories
    ENABLE_PUSH_CREATE_USER = true

    [server]
    DOMAIN = localhost
    ROOT_URL = http://localhost:3000/
    HTTP_ADDR = 127.0.0.1
    HTTP_PORT = 3000
    SSH_DOMAIN = y0usaf-server
    START_SSH_SERVER = true
    SSH_PORT = 2222
    LFS_START_SERVER = true

    [session]
    COOKIE_NAME = session

    [security]
    INSTALL_LOCK = true
    SECRET_KEY = $(cat "$secret_dir/secret_key")
    INTERNAL_TOKEN = $(cat "$secret_dir/internal_token")

    [oauth2]
    JWT_SECRET = $(cat "$secret_dir/oauth2_jwt_secret")

    [lfs]
    PATH = /var/lib/forgejo/lfs
    JWT_SECRET = $(cat "$secret_dir/lfs_jwt_secret")
    EOF

        export USER=forgejo
        export HOME=/var/lib/forgejo
        export FORGEJO_WORK_DIR=/var/lib/forgejo
        export FORGEJO_CUSTOM=/var/lib/forgejo/custom

        ${pkgs.forgejo}/bin/forgejo migrate
        ${pkgs.forgejo}/bin/forgejo admin regenerate hooks || true
        if [ -r /var/lib/forgejo/.ssh/authorized_keys ]; then
          ${pkgs.forgejo}/bin/forgejo admin regenerate keys || true
        fi
  '';

  forgejoStart = pkgs.writeShellScript "forgejo-start" ''
    export USER=forgejo
    export HOME=/var/lib/forgejo
    export FORGEJO_WORK_DIR=/var/lib/forgejo
    export FORGEJO_CUSTOM=/var/lib/forgejo/custom
    exec ${pkgs.forgejo}/bin/forgejo web --pid /run/forgejo/forgejo.pid
  '';

  nginxStart = pkgs.writeShellScript "nginx-start" ''
    exec ${pkgs.nginx}/bin/nginx -c /etc/nginx/nginx.conf -g 'daemon off;'
  '';

  servicePath = with pkgs; [
    coreutils
    curl
    findutils
    gnugrep
    gnused
    jq
    libxml2
    procps
    shadow
    util-linux
    xz
    gzip
  ];

  n8nStart = pkgs.writeShellScript "n8n-start" ''
    exec ${pkgs.n8n}/bin/n8n
  '';

  mediamtxEnv = pkgs.writeShellScript "mediamtx-env" ''
    set -euo pipefail

    public_ip="$(${pkgs.curl}/bin/curl -fsS https://api.ipify.org || true)"
    if [ -n "$public_ip" ]; then
      printf 'MTX_WEBRTCADDITIONALHOSTS=%s\n' "$public_ip" > /etc/mediamtx.env
    else
      printf '# no public ip available\n' > /etc/mediamtx.env
    fi
  '';

  mediamtxStart = pkgs.writeShellScript "mediamtx-start" ''
    export $(grep -v '^#' /etc/mediamtx.env | xargs -r)
    exec ${pkgs.mediamtx}/bin/mediamtx /etc/mediamtx.yaml
  '';
in {
  networking.hostName = lib.mkDefault "finix-y0usaf-server";
  time.timeZone = "America/Toronto";

  boot.kernelModules = [
    "tun"
    "veth"
    "bridge"
    "br_netfilter"
    "overlay"
  ];

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs;
    [
      curl
      docker
      forgejo
      git
      gnugrep
      gnused
      inetutils
      iproute2
      iputils
      jq
      mediamtx
      n8n
      neovim
      nh
      nushell
      postgresql
      procps
      syncthing
      tailscale
      wget
      zellij
      zsh
    ]
    ++ lib.optionals (inputs ? hermes-agent) [
      inputs.hermes-agent.packages."${pkgs.stdenv.hostPlatform.system}".default
    ];

  environment.etc = {
    "docker/daemon.json".source = dockerConfig;
    "nginx/nginx.conf".source = nginxConfig;
    "mediamtx.yaml".source = mediamtxConfig;
    "ssh/authorized_keys.d/y0usaf".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6ZHkn1pACV406TM5yUCRt/874vybgpUW3sUKka9nAC y0usaf@y0usaf-desktop
    '';
  };

  networking.hosts = {
    "100.90.54.18" = ["syncthing-desktop"];
    "100.105.204.116" = ["forgejo" "syncthing-server"];
  };

  services.mdevd.enable = true;
  services.sysklogd.enable = true;
  services.dhcpcd.enable = lib.mkDefault (!isTestVm);
  programs.resolvconf.enable = lib.mkDefault (!isTestVm);
  services.getty = {
    enable = true;
    ttys = ["ttyS0"];
  };
  services.nftables = {
    enable = true;
    configFile = nftablesConfig;
  };
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      KbdInteractiveAuthentication = false;
      AuthorizedKeysFile = ".ssh/authorized_keys Tokens/authorized_keys /etc/ssh/authorized_keys.d/%u";
    };
  };

  programs.sudo.enable = true;
  environment.etc.sudoers.text = lib.mkAfter ''
    y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
  '';

  users.users = {
    y0usaf = {
      isNormalUser = true;
      home = "/home/y0usaf";
      shell = "${pkgs.nushell}/bin/nu";
      extraGroups = ["wheel" "docker"];
      packages = with pkgs;
        [
          docker
          git
          nh
          neovim
          nushell
          syncthing
          tailscale
          zellij
          zsh
        ]
        ++ lib.optionals (inputs ? hermes-agent) [
          inputs.hermes-agent.packages."${pkgs.stdenv.hostPlatform.system}".default
        ];
    };

    forgejo = {
      isSystemUser = true;
      group = "forgejo";
      home = "/var/lib/forgejo";
    };

    postgres = {
      isSystemUser = true;
      group = "postgres";
      home = "/var/lib/postgresql";
    };

    n8n = {
      isSystemUser = true;
      group = "n8n";
      home = "/var/lib/n8n";
    };

    mediamtx = {
      isSystemUser = true;
      group = "mediamtx";
      home = "/var/lib/mediamtx";
    };

    nginx = {
      isSystemUser = true;
      group = "nginx";
      home = "/var/lib/nginx";
    };
  };

  users.groups = {
    docker = {};
    forgejo = {};
    postgres = {};
    n8n = {};
    mediamtx = {};
    nginx = {};
  };

  finit.tmpfiles.rules = [
    "d /tmp 1777 root root"
    "d /run/docker 0755 root root"
    "d /run/tailscale 0755 root root"
    "d /run/postgresql 0755 postgres postgres"
    "d /run/forgejo 0755 forgejo forgejo"
    "d /run/nginx 0755 nginx nginx"
    "d /var/lib/docker 0755 root root"
    "d /var/lib/containerd 0755 root root"
    "d /var/lib/tailscale 0755 root root"
    "d /var/lib/postgresql 0755 postgres postgres"
    "d /var/lib/postgresql/data 0700 postgres postgres"
    "d /var/lib/forgejo 0750 forgejo forgejo"
    "d /var/lib/forgejo/.ssh 0700 forgejo forgejo"
    "d /var/lib/forgejo/custom 0750 forgejo forgejo"
    "d /var/lib/forgejo/custom/conf 0750 forgejo forgejo"
    "d /var/lib/forgejo/data 0750 forgejo forgejo"
    "d /var/lib/forgejo/log 0750 forgejo forgejo"
    "d /var/lib/forgejo/lfs 0750 forgejo forgejo"
    "d /var/lib/forgejo/repositories 0750 forgejo forgejo"
    "d /var/lib/n8n 0750 n8n n8n"
    "d /var/lib/mediamtx 0750 mediamtx mediamtx"
    "d /var/log/nginx 0755 nginx nginx"
    "d /var/lib/nginx 0755 nginx nginx"
    "d /var/lib/nginx/client_temp 0755 nginx nginx"
    "d /var/lib/nginx/proxy_temp 0755 nginx nginx"
    "d /var/lib/nginx/fastcgi_temp 0755 nginx nginx"
    "d /var/lib/nginx/uwsgi_temp 0755 nginx nginx"
    "d /var/lib/nginx/scgi_temp 0755 nginx nginx"
    "d /home/y0usaf 0700 y0usaf users"
    "d /home/y0usaf/.config 0700 y0usaf users"
    "d /home/y0usaf/.config/syncthing 0700 y0usaf users"
    "d /home/y0usaf/.local 0700 y0usaf users"
    "d /home/y0usaf/.local/state 0700 y0usaf users"
    "d /home/y0usaf/.local/state/syncthing 0700 y0usaf users"
    "d /home/y0usaf/.hermes 0700 y0usaf users"
    "d /home/y0usaf/Tokens 0755 y0usaf users"
    "d /home/y0usaf/Music 0755 y0usaf users"
    "d /home/y0usaf/DCIM 0755 y0usaf users"
    "d /home/y0usaf/Pictures 0755 y0usaf users"
  ];

  finit.services.dockerd = {
    description = "docker daemon";
    cgroup.delegate = true;
    command = "${dockerStart}";
    conditions = ["service/syslogd/ready" "net/lo/up"];
    log = true;
    notify = "systemd";
    path = servicePath ++ [pkgs.docker pkgs.kmod];
  };

  finit.services.tailscaled = {
    description = "tailscale daemon";
    command = "${tailscaledStart}";
    conditions = ["service/syslogd/ready" "net/lo/up"];
    log = true;
    path = servicePath ++ [pkgs.tailscale];
  };

  finit.services.syncthing = {
    description = "syncthing daemon";
    user = "y0usaf";
    group = "users";
    command = "${syncthingStart}";
    conditions = ["net/lo/up"];
    log = true;
    path = servicePath ++ [pkgs.syncthing];
    environment = {
      STNORESTART = "yes";
      STNOUPGRADE = "yes";
    };
  };

  finit.tasks.syncthing-setup = {
    description = "apply syncthing devices and folders";
    user = "y0usaf";
    group = "users";
    command = "${syncthingSetup}";
    conditions = ["service/syncthing/running"];
    log = true;
    path = servicePath ++ [pkgs.syncthing];
    remain = true;
  };

  finit.services.postgresql = {
    description = "postgresql database";
    user = "postgres";
    group = "postgres";
    command = "${postgresStart}";
    conditions = ["service/syslogd/ready" "net/lo/up"];
    log = true;
    notify = "systemd";
    path = servicePath ++ [pkgs.postgresql pkgs.shadow];
    pre = "${postgresInit}";
  };

  finit.tasks.postgresql-setup = {
    description = "create forgejo database and role";
    user = "postgres";
    group = "postgres";
    command = "${postgresSetup}";
    conditions = ["service/postgresql/ready"];
    log = true;
    path = servicePath ++ [pkgs.postgresql];
    remain = true;
  };

  finit.tasks.forgejo-setup = {
    description = "prepare forgejo config and migrate database";
    user = "forgejo";
    group = "forgejo";
    command = "${forgejoSetup}";
    conditions = ["task/postgresql-setup/success"];
    log = true;
    path = servicePath ++ [pkgs.forgejo pkgs.git];
    remain = true;
    environment = {
      USER = "forgejo";
      HOME = "/var/lib/forgejo";
      FORGEJO_WORK_DIR = "/var/lib/forgejo";
      FORGEJO_CUSTOM = "/var/lib/forgejo/custom";
    };
  };

  finit.services.forgejo = {
    description = "forgejo service";
    user = "forgejo";
    group = "forgejo";
    command = "${forgejoStart}";
    conditions = ["task/forgejo-setup/success" "net/lo/up"];
    log = true;
    notify = "systemd";
    path = servicePath ++ [pkgs.forgejo pkgs.git];
    environment = {
      USER = "forgejo";
      HOME = "/var/lib/forgejo";
      FORGEJO_WORK_DIR = "/var/lib/forgejo";
      FORGEJO_CUSTOM = "/var/lib/forgejo/custom";
    };
  };

  finit.services.nginx = {
    description = "nginx reverse proxy";
    command = "${nginxStart}";
    conditions = ["service/syslogd/ready" "net/lo/up"];
    log = true;
    path = servicePath ++ [pkgs.nginx];
    reload = "${pkgs.nginx}/bin/nginx -s reload -c /etc/nginx/nginx.conf";
  };

  finit.services.n8n = {
    description = "n8n service";
    user = "n8n";
    group = "n8n";
    command = "${n8nStart}";
    conditions = ["service/syslogd/ready" "net/lo/up"];
    log = true;
    path = servicePath ++ [pkgs.n8n pkgs.nodejs pkgs.python3];
    environment = {
      HOME = "/var/lib/n8n";
      N8N_PORT = "5678";
      N8N_HOST = "127.0.0.1";
      N8N_USER_FOLDER = "/var/lib/n8n";
      N8N_SECURE_COOKIE = "false";
      TZ = config.time.timeZone;
      GENERIC_TIMEZONE = config.time.timeZone;
    };
  };

  finit.tasks.mediamtx-env = {
    description = "prepare mediamtx env file";
    command = "${mediamtxEnv}";
    conditions = ["net/lo/up"];
    log = true;
    path = servicePath;
    remain = true;
  };

  finit.services.mediamtx = {
    description = "mediamtx service";
    user = "mediamtx";
    group = "mediamtx";
    command = "${mediamtxStart}";
    conditions = ["task/mediamtx-env/success" "net/lo/up"];
    log = true;
    path = servicePath ++ [pkgs.mediamtx];
  };
}
