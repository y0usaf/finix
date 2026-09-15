# Hermes remote gateway: the native `hermes serve` backend (the JSON-RPC /
# WebSocket API + web dashboard the desktop app and remote clients attach to)
# exposed on the tailnet. Discovered from the upstream docs:
# https://hermes-agent.nousresearch.com/docs/user-guide/multi-connection-desktop
#
# Hermes as of the June 2026 hardening FAILS CLOSED on a non-loopback bind
# unless an auth provider is registered: there is no unauthenticated public
# dashboard option and `--insecure` is a deprecated no-op. The bundled
# username/password provider (`dashboard_auth/basic`) is the supported choice
# for a trusted network / VPN, which is what the tailnet is.
#
# The credentials are read at runtime from an env file that is NOT in the Nix
# store, so no secret is baked into a generation or printed to logs. The bind
# address is the machine's tailnet IPv4; the desktop firewall already accepts
# the tailscale0 interface wholesale, so nothing else is exposed.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.dev.ai.hermes.remoteGateway;
  user = config.user.name;
  home = config.users.users.${user}.home;
  runtimeDir = "/run/user/${toString config.users.users.${user}.uid}";
in {
  options.user.dev.ai.hermes.remoteGateway = {
    enable = lib.mkEnableOption "Hermes remote gateway (headless `hermes serve` backend + web dashboard)";

    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address `hermes serve` binds. A non-loopback bind engages Hermes's
        mandatory auth gate, so an auth provider must be configured (see
        `authEnvFile`). Use the machine's tailnet IPv4 (`tailscale ip -4`) to
        keep the gateway reachable only from the tailnet.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9119;
      description = "Port `hermes serve` listens on (Hermes's default is 9119).";
    };

    authEnvFile = lib.mkOption {
      type = lib.types.str;
      default = "${home}/.hermes/remote-gateway.env";
      description = ''
        Runtime env file (mode 0600) sourced before `hermes serve` starts.
        Holds the username/password provider credentials
        (HERMES_DASHBOARD_BASIC_AUTH_USERNAME / _PASSWORD / _SECRET) so they
        stay out of the Nix store and out of logs. Created and owned at
        runtime, never declared here.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    finit.services.hermes-remote-gateway = {
      description = "Hermes remote gateway (hermes serve)";
      inherit user;
      environment = {
        HOME = home;
        HERMES_HOME = "${home}/.hermes";
        XDG_RUNTIME_DIR = runtimeDir;
      };
      command = pkgs.writeShellScript "hermes-remote-gateway-start" ''
        set -eu
        export PATH=${lib.concatStringsSep ":" [
          "${pkgs.coreutils}/bin"
          "/run/current-system/sw/bin"
          "/run/wrappers/bin"
          "${home}/.nix-profile/bin"
          "${home}/.local/state/nix/profile/bin"
          "/nix/var/nix/profiles/default/bin"
        ]}:$PATH

        # The dashboard's embedded chat spawns a PTY child; wait for the
        # boot-created runtime dir (xdg-runtime-dir in session.nix owns it).
        for _ in $(seq 1 60); do
          [ -d ${lib.escapeShellArg runtimeDir} ] && break
          sleep 1
        done

        # Load the username/password provider credentials. Sourced, not read
        # at build time, so the secret never enters the store.
        auth_env=${lib.escapeShellArg cfg.authEnvFile}
        if [ -r "$auth_env" ]; then
          set -a
          . "$auth_env"
          set +a
        else
          echo "hermes-remote-gateway: $auth_env missing; refusing a non-loopback bind without an auth provider" >&2
          exit 1
        fi

        exec ${config.user.dev.ai.hermes.packages.hermesFull}/bin/hermes serve \
          --host ${lib.escapeShellArg cfg.listenAddress} \
          --port ${toString cfg.port} \
          --skip-build
      '';
      # tailscale0 must be up before a tailnet bind can succeed.
      conditions = ["net/lo/up" "net/tailscale0/up"];
      log = true;
    };
  };
}
