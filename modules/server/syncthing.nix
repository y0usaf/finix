{
  config,
  pkgs,
  ...
}: let
  inherit (config.user) name homeDirectory;
in {
  users = {
    users.nginx = {
      isSystemUser = true;
      group = "nginx";
    };
    groups.nginx = {};
  };

  finit = {
    tmpfiles.rules = ["d /run/nginx 0755 root root"];

    services = {
      syncthing = {
        description = "syncthing file sync (${name})";
        user = name;
        command = "${pkgs.syncthing}/bin/syncthing --config=${homeDirectory}/.config/syncthing --data=${homeDirectory}/.config/syncthing --gui-address=127.0.0.1:8384 --no-browser";
        environment.HOME = homeDirectory;
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
}
