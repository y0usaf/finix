{
  config,
  lib,
  pkgs,
  ...
}: {
  options.services.nginx-reverse-proxy = lib.mkEnableOption "Enable Nginx reverse proxy for Tailscale services";

  config = lib.mkIf config.services.nginx-reverse-proxy {
    security.acme.acceptTerms = true;

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts."forgejo" = {
        addSSL = true;
        forceSSL = false;
        enableACME = false;

        # Self-signed certificate for private Tailscale network
        sslCertificate = "/var/lib/nginx/forgejo.crt";
        sslCertificateKey = "/var/lib/nginx/forgejo.key";

        locations."/" = {
          proxyPass = "http://100.105.204.116:3000";
          proxyWebsockets = true;
        };
      };
    };

    # Generate self-signed certificate and ensure proper permissions
    systemd.services.nginx-selfsigned-cert = {
      description = "Generate and fix permissions for Nginx self-signed certificate";
      before = ["nginx.service"];
      wantedBy = ["multi-user.target"];
      script = ''
        mkdir -p /var/lib/nginx
        if [ ! -f /var/lib/nginx/forgejo.key ]; then
          ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:2048 -keyout /var/lib/nginx/forgejo.key -out /var/lib/nginx/forgejo.crt -days 365 -nodes -subj "/CN=forgejo"
        fi
        # Always ensure correct permissions so nginx can read the key
        chmod 644 /var/lib/nginx/forgejo.key
        chmod 644 /var/lib/nginx/forgejo.crt
        chown nginx:nginx /var/lib/nginx/forgejo.key /var/lib/nginx/forgejo.crt
      '';
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
    };
  };
}
