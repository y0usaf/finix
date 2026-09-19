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

    apiKeyFile = lib.mkOption {
      type = lib.types.path;
      default = "${home}/Tokens/AI_GATEWAY_API_KEY.txt";
      description = ''
        Runtime credential file holding the AI Gateway API key. The packaged
        `hermes` wrapper sources `load-credentials.sh`, which exports
        AI_GATEWAY_API_KEY from `HERMES_API_KEY_FILE`; the daemons below only
        get that because they exec that wrapper. The path lives outside the
        store so the secret is never baked into a generation.
      '';
    };

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
    # Background Hermes gateway (`hermes gateway run`). Separate process from
    # `hermes serve` above and NOT optional: the gateway is the only thing that
    # hosts the embedded kanban dispatcher (`kanban.dispatch_in_gateway`) plus
    # auto-decompose and the kanban notifier. With no messaging platform
    # configured it still runs, for exactly that reason (upstream logs "Gateway
    # will continue running for cron job execution"). Without it, `ready`
    # cards sit still forever and `triage` cards are never decomposed.
    #
    # `hermes gateway install` writes a systemd/launchd unit, which finix does
    # not have, so the service is declared here in finit like every other
    # daemon. A machine-global singleton lock
    # (~/.hermes/kanban/.dispatcher.lock) keeps exactly one dispatcher across
    # all profiles/gateways, so this cannot race the desktop or `hermes serve`.
    finit.services.hermes-gateway = {
      description = "Hermes gateway (embedded kanban dispatcher + cron)";
      inherit user;
      environment = {
        HOME = home;
        HERMES_HOME = "${home}/.hermes";
        XDG_RUNTIME_DIR = runtimeDir;
      };
      command = pkgs.writeShellScript "hermes-gateway-start" ''
        set -eu
        export PATH=${lib.concatStringsSep ":" [
          "${pkgs.coreutils}/bin"
          "/run/current-system/sw/bin"
          "/run/wrappers/bin"
          "${home}/.nix-profile/bin"
          "${home}/.local/state/nix/profile/bin"
          "/nix/var/nix/profiles/default/bin"
        ]}:$PATH

        # Workers and steady-state locks live under the boot-created runtime
        # dir (xdg-runtime-dir in session.nix owns it).
        for _ in $(seq 1 60); do
          [ -d ${lib.escapeShellArg runtimeDir} ] && break
          sleep 1
        done

        # The packaged wrapper sources load-credentials.sh and exports
        # AI_GATEWAY_API_KEY from HERMES_API_KEY_FILE at exec time. Set it
        # explicitly so the service does not silently depend on the
        # build-time default, and fail loudly if the key is missing.
        key_file=${lib.escapeShellArg cfg.apiKeyFile}
        if [ ! -r "$key_file" ]; then
          echo "hermes-gateway: $key_file missing; worker dispatch would have no inference credential" >&2
          exit 1
        fi
        export HERMES_API_KEY_FILE="$key_file"

        # Same runtime-only credential file as `hermes serve`: dispatch spawns
        # worker agents, which need the inference key. Never baked into the
        # store, never echoed (mode 0600).
        auth_env=${lib.escapeShellArg cfg.authEnvFile}
        if [ -r "$auth_env" ]; then
          set -a
          . "$auth_env"
          set +a
        else
          echo "hermes-gateway: $auth_env missing; refusing to start without an inference credential" >&2
          exit 1
        fi

        # Foreground (supervised by finit). `hermes gateway restart` is the
        # manual equivalent; do not also run `hermes gateway start`.
        exec ${config.user.dev.ai.hermes.packages.hermesFull}/bin/hermes gateway run
      '';
      conditions = ["net/lo/up"];
      log = true;
    };

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
