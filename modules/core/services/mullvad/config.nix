{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.mullvad;
  antiCensorshipModes = [
    "auto"
    "off"
    "wireguard-port"
    "udp2tcp"
    "shadowsocks"
    "quic"
    "lwo"
  ];
  boolToMullvad = value:
    if value
    then "on"
    else "off";
  shouldApplySettings =
    cfg.autoConnect
    != null
    || cfg.lockdownMode != null
    || cfg.antiCensorship.mode != null
    || cfg.antiCensorship.shadowsocksPort != null;
in {
  options.services.mullvad = {
    enableVPN = lib.mkEnableOption "Mullvad VPN";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.mullvad-vpn;
      defaultText = lib.literalExpression "pkgs.mullvad-vpn";
      description = ''
        Mullvad package to install and run.

        Use pkgs.mullvad for CLI-only usage, or pkgs.mullvad-vpn for the GUI.
      '';
    };

    enableExcludeWrapper = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable the mullvad-exclude setuid wrapper for split tunneling commands.
      '';
    };

    enableEarlyBootBlocking = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable Mullvad's early boot firewall blocker before network configuration.
      '';
    };

    autoConnect = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to configure Mullvad to connect automatically when the daemon starts.
      '';
    };

    lockdownMode = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to block Internet access unless Mullvad is connected.
      '';
    };

    antiCensorship = {
      mode = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum antiCensorshipModes);
        default = null;
        description = ''
          Mullvad anti-censorship mode to apply through the Mullvad CLI.
        '';
      };

      shadowsocksPort = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.port (lib.types.enum ["any"]));
        default = null;
        example = 443;
        description = ''
          Port for Mullvad's Shadowsocks anti-censorship mode. Use 443 on
          restrictive networks when automatic port selection fails.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enableVPN {
    services.mullvad-vpn = {
      enable = true;
      package = cfg.package;
      inherit (cfg) enableExcludeWrapper enableEarlyBootBlocking;
    };

    systemd.services.mullvad-settings = lib.mkIf shouldApplySettings {
      description = "Apply Mullvad VPN settings";
      wantedBy = ["multi-user.target"];
      wants = ["mullvad-daemon.service"];
      after = ["mullvad-daemon.service"];
      path = [cfg.package pkgs.coreutils];
      script = ''
        set -euo pipefail

        for _ in $(seq 1 60); do
          if mullvad status >/dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        mullvad status >/dev/null

        ${lib.optionalString (cfg.antiCensorship.shadowsocksPort != null) ''
          mullvad anti-censorship set shadowsocks --port ${toString cfg.antiCensorship.shadowsocksPort}
        ''}
        ${lib.optionalString (cfg.antiCensorship.mode != null) ''
          mullvad anti-censorship set mode ${cfg.antiCensorship.mode}
        ''}
        ${lib.optionalString (cfg.autoConnect != null) ''
          mullvad auto-connect set ${boolToMullvad cfg.autoConnect}
        ''}
        ${lib.optionalString (cfg.lockdownMode != null) ''
          mullvad lockdown-mode set ${boolToMullvad cfg.lockdownMode}
        ''}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };
}
