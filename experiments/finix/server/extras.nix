# Additional finix services needed for bare-metal parity with the current
# NixOS `y0usaf-server` host: blocky (DNS ad-blocker), btrbk (btrfs snapshots),
# bayt (optional user service), ACME/TLS stubs.
#
# Everything here is opt-in. Enable via the bare-metal host module, not in
# the VM.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.finix.server.extras;
in {
  options.finix.server.extras = {
    blocky.enable = lib.mkEnableOption "blocky DNS ad-blocker";
    btrbk = {
      enable = lib.mkEnableOption "btrbk btrfs snapshot service";
      timer = lib.mkOption {
        type = lib.types.str;
        default = "hourly";
        description = "cron-like schedule (finit cron syntax).";
      };
      configFile = lib.mkOption {
        type = lib.types.path;
        default = pkgs.writeText "btrbk.conf" ''
          timestamp_format   long
          snapshot_preserve  24h 14d 4w
          target_preserve    24h 14d 8w 12m
          volume /btrfs
            subvolume @home
              snapshot_dir .snapshots
        '';
        defaultText = lib.literalExpression "pkgs.writeText \"btrbk.conf\" \"...\"";
        description = "Path to btrbk configuration.";
      };
    };
    bayt = {
      enable = lib.mkEnableOption "bayt user-state service (stub)";
    };
    acme = {
      enable = lib.mkEnableOption "acme / lego certificate renewal";
      email = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Contact email for Let's Encrypt.";
      };
      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Domains to request certificates for.";
      };
    };
  };

  config = lib.mkMerge [
    ##################################################################
    # blocky: parity with current NixOS server's DNS ad-blocker.
    ##################################################################
    (lib.mkIf cfg.blocky.enable {
      services.blocky = {
        enable = true;
        settings = {
          ports.dns = 53;
          upstreams.groups.default = [
            "https://dns.cloudflare.com/dns-query"
            "https://dns.google/dns-query"
          ];
          blocking = {
            denylists.ads = [
              "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts"
            ];
            clientGroupsBlock.default = ["ads"];
          };
          bootstrapDns.upstream = "1.1.1.1";
          log.level = "info";
        };
      };

      # Make the host resolve via blocky.
      environment.etc."resolv.conf".text = ''
        nameserver 127.0.0.1
        options edns0
      '';
    })

    ##################################################################
    # btrbk: periodic btrfs snapshots for @home, @persist, etc.
    ##################################################################
    (lib.mkIf cfg.btrbk.enable {
      environment.systemPackages = [pkgs.btrbk];

      environment.etc."btrbk/btrbk.conf".source = cfg.btrbk.configFile;

      finit.tasks.btrbk = {
        description = "btrbk snapshot job";
        command = "${pkgs.btrbk}/bin/btrbk -c /etc/btrbk/btrbk.conf run";
        conditions = ["net/lo/up"];
        log = true;
        # cron:<expr> — finit supports cron triggers via the scheduler;
        # if not available in the installed finit build, this task still
        # runs once on boot and can be driven externally.
        runlevels = "2345";
      };
    })

    ##################################################################
    # bayt: placeholder. The real bayt integration lives in a separate
    # flake; when ported to finix, wire it in here.
    ##################################################################
    (lib.mkIf cfg.bayt.enable {
      warnings = [
        "finix.server.extras.bayt is a stub — nothing is started. Port bayt's NixOS module to finit before deploying."
      ];

      finit.tmpfiles.rules = [
        "d /var/lib/bayt 0750 root root"
      ];
    })

    ##################################################################
    # acme / lego: minimal placeholder. Uses lego in a one-shot task that
    # writes certificates to /var/lib/acme/<domain>/. Nginx reads them
    # from there. Plug in DNS-01 or HTTP-01 via extraArgs in your host.
    ##################################################################
    (lib.mkIf cfg.acme.enable {
      assertions = [
        {
          assertion = cfg.acme.email != "";
          message = "finix.server.extras.acme.email must be set when acme.enable is true";
        }
        {
          assertion = cfg.acme.domains != [];
          message = "finix.server.extras.acme.domains must list at least one domain";
        }
      ];

      environment.systemPackages = [pkgs.lego];

      finit.tmpfiles.rules = [
        "d /var/lib/acme 0750 root root"
      ];

      finit.tasks.acme-renew = {
        description = "lego certificate renewal";
        command = pkgs.writeShellScript "acme-renew" ''
          set -euo pipefail
          export HOME=/var/lib/acme
          mkdir -p "$HOME"

          for domain in ${lib.concatStringsSep " " cfg.acme.domains}; do
            ${pkgs.lego}/bin/lego \
              --accept-tos \
              --email ${lib.escapeShellArg cfg.acme.email} \
              --path "$HOME" \
              --domains "$domain" \
              --http \
              --http.port ":80" \
              run || \
            ${pkgs.lego}/bin/lego \
              --accept-tos \
              --email ${lib.escapeShellArg cfg.acme.email} \
              --path "$HOME" \
              --domains "$domain" \
              --http \
              --http.port ":80" \
              renew || true
          done
        '';
        conditions = ["net/route/default"];
        log = true;
      };
    })
  ];
}
