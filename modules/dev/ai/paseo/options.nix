# Options for the Paseo daemon (user.dev.paseo).
#
# Paseo is a self-hosted daemon that launches and manages coding-agent CLIs
# (Claude Code, Codex, OpenCode, Pi, ...). It ships a NixOS module
# (services.paseo, systemd-based); finix runs finit, so this family
# replicates the same surface as a finit service (pattern:
# hosts/y0usaf-server/finix/hermes.nix). The daemon must run as the real
# user so the agents it spawns inherit the user's PATH, git, ssh, and API
# credentials.
{lib, ...}: let
  inherit (lib) types;
in {
  options.user.dev.paseo = {
    enable = lib.mkEnableOption "Paseo daemon for coding-agent orchestration";

    dataDir = lib.mkOption {
      type = types.str;
      default = ".paseo";
      description = ''
        Paseo home directory (PASEO_HOME), relative to the user's home.
        Holds config.json, device pairings, and agent session state.
      '';
    };

    listenAddress = lib.mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address the daemon binds. 127.0.0.1 plus relay, or a LAN IP.";
    };

    port = lib.mkOption {
      type = types.port;
      default = 6767;
      description = "Daemon listen port.";
    };

    relay = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Use the hosted relay (app.paseo.sh) for remote access. On: phone
          works from anywhere. Off (--no-relay): direct LAN/Tailscale only.
        '';
      };
    };

    # Extra daemon environment. PATH is managed by the service module so
    # spawned agents can find the user's CLIs; additional vars land here.
    environment = lib.mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Extra environment variables for the Paseo daemon.";
    };

    environmentFiles = lib.mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Files whose contents become environment variables of the daemon (and
        therefore of every agent it spawns). Each file's basename, extension
        stripped and uppercased with non-alphanumerics mapped to _, names the
        variable; the trimmed file content is the value. Keeps API keys out of
        the store (pattern: ~/Tokens/*.txt, one bare key per file).
      '';
    };

    group = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Group the daemon runs as. Default: the user's own group (user.name).
        Set explicitly when the user's primary group differs (e.g. 'users').
      '';
    };

    reasonix = {
      enable = lib.mkEnableOption ''
        reasonix as a Paseo ACP provider. Registers a custom ACP provider in
        Paseo's daemon-owned config.json (agents.providers.reasonix with
        extends="acp", command=[reasonix, acp]) via a non-destructive manzil
        merge, so it shows up under the Paseo app as "Reasonix". reasonix must
        also be installed (user.dev.reasonix.enable) so the CLI is on PATH.
      '';
    };
  };
}
