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
  home = config.user.homeDirectory;
  agentConfigEnv = lib.filterAttrs (_: value: value != null) {
    CLAUDE_CONFIG_DIR = config.environment.variables.CLAUDE_CONFIG_DIR or null;
    CODEX_HOME = config.environment.variables.CODEX_HOME or null;
  };
in {
  options.user.dev.paseo = {
    listenAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address the daemon binds. 127.0.0.1 plus relay, or a LAN IP.";
    };

    relay = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Use the hosted relay (app.paseo.sh) for remote access. On: phone
          works from anywhere. Off (--no-relay): direct LAN/Tailscale only.
        '';
      };
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["/home/y0usaf/Tokens/AI_GATEWAY_API_KEY.txt"];
      description = ''
        Files whose contents become environment variables of the daemon (and
        therefore of every agent it spawns). Each file's basename, extension
        stripped and uppercased with non-alphanumerics mapped to _, names the
        variable; the trimmed file content is the value. Keeps API keys out of
        the store (pattern: ~/Tokens/*.txt, one bare key per file).
      '';
    };
  };

  config = {
    environment.systemPackages = [paseo];

    finit.services.paseo = {
      description = "Paseo - self-hosted daemon for AI coding agents";
      user = config.user.name;
      group = "users";
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
          PASEO_HOME = "${home}/.paseo";
          PASEO_LISTEN = "${cfg.listenAddress}:6767";
        }
        // agentConfigEnv;
      conditions = ["net/lo/up" "net/tailscale0/up"];
      log = true;
    };

    manzil.users."${config.user.name}".files.".paseo/config.json" = {
      type = "merge";
      format = "json";
      value.agents.providers = {
        fx = {
          extends = "acp";
          label = "fx";
          command = ["omfx" "acp"];
          env = {
            FX_PERMISSION_MODE = "yolo";
          };
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
