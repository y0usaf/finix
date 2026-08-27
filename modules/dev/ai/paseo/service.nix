# Paseo daemon as a finit service (desktop + always-on server host, real user).
#
# Runs paseo-server (the foreground supervisor entrypoint) as the real
# user. The daemon spawns coding-agent CLIs (claude, codex, opencode,
# pi, ...), which sit in environment.systemPackages -> /run/current-system/
# sw/bin, so the service PATH includes that dir plus the user's profile
# bins (mirroring the NixOS module's inheritUserEnvironment). Relay on by
# default: phone reaches the daemon through app.paseo.sh regardless of LAN.
# Relay off (--no-relay) + tailnet listen = fully self-hosted direct path.
{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.paseo;
  inherit (pkgs.stdenv.hostPlatform) system;
  paseo = flakeInputs.paseo.packages."${system}".default;
  fx = flakeInputs.fx-flake.packages."${system}".default;
  home = config.user.homeDirectory;
  homePaseo = "${home}/${cfg.dataDir}";
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [paseo fx];

    finit.services.paseo = {
      description = "Paseo - self-hosted daemon for AI coding agents";
      user = config.user.name;
      group =
        if cfg.group != null
        then cfg.group
        else config.user.name;
      command = "${pkgs.writeShellScript "paseo-server-start" ''
        set -eu
        export PATH=${lib.concatStringsSep ":" [
          "${pkgs.coreutils}/bin"
          "/run/current-system/sw/bin"
          "/run/wrappers/bin"
          "${home}/.nix-profile/bin"
          "${home}/.local/state/nix/profile/bin"
          "/nix/var/nix/profiles/default/bin"
        ]}:$PATH
        if [ -n '${builtins.concatStringsSep " " cfg.environmentFiles}' ]; then
          for f in ${builtins.concatStringsSep " " cfg.environmentFiles}; do
            [ -r "$f" ] || continue
            name=$(basename "$f"); name="''${name%.*}"
            name=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')
            value=$(cat "$f")
            export "$name"="$value"
          done
        fi
        exec ${paseo}/bin/paseo-server ${lib.optionalString (!cfg.relay.enable) "--no-relay"}
      ''}";
      environment =
        {
          HOME = home;
          PASEO_HOME = homePaseo;
          PASEO_LISTEN = "${cfg.listenAddress}:${toString cfg.port}";
        }
        // cfg.environment;
      conditions = ["net/lo/up" "net/tailscale0/up"];
      log = true;
    };

    # Register custom ACP providers without replacing Paseo-owned runtime state.
    # Commands resolve from the daemon PATH, including /run/current-system/sw/bin.
    manzil.users."${config.user.name}".files.".paseo/config.json" = {
      type = "merge";
      format = "json";
      value.agents.providers = {
        fx = {
          extends = "acp";
          label = "fx";
          command = ["fx" "acp"];
        };
        reasonix = {
          extends = "acp";
          label = "Reasonix";
          description = "Reasonix cache-first coding agent";
          command = ["reasonix" "acp"];
        };
      };
    };
  };
}
