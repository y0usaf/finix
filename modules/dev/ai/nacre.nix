{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.nacre;
  nacre = flakeInputs.nacre.packages.${pkgs.stdenv.hostPlatform.system};
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";

  # Leaves PATH alone: it execs nacre-start, and bots inherit whatever PATH this sees.
  waitRuntimeDir = pkgs.writeShellScript "wait-nacre-runtime" ''
    for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
      [ -d ${runtimeDir} ] && exec "$@"
      ${pkgs.coreutils}/bin/sleep 1
    done
    echo "wait-nacre-runtime: ${runtimeDir} never appeared" >&2
    exit 1
  '';

  start = pkgs.writeShellScript "nacre-start" ''
    set -eu
    for f in ${lib.escapeShellArgs cfg.environmentFiles}; do
      [ -r "$f" ] || continue
      name=$(basename "$f"); name="''${name%.*}"
      name=$(printf '%s' "$name" | tr '[:lower:]' '[:upper:]' | tr -c 'A-Z0-9_' '_')
      export "$name"="$(cat "$f")"
    done
    exec ${lib.getExe nacre.default} --wait
  '';
in {
  options.user.dev.nacre = {
    enable = lib.mkEnableOption "the nacre daemon as a service at boot, so the deck is up without the app";

    app.enable = lib.mkEnableOption "the nacre window (Electron) on this machine; it starts the daemon only when none answers and leaves it running on close";

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["${user.home}/Tokens/AI_GATEWAY_API_KEY.txt"];
      description = ''
        Files whose contents become environment variables of the daemon (and so
        of every bot it runs), named like paseo's: basename without extension,
        uppercased. Unreadable files are skipped. Port, host and plugins stay in
        nacre's own ~/.config/nacre/config.json.
      '';
    };
  };

  config = lib.mkMerge [
    {
      finix.persistence.allowlist.users.${userName}.directories = [
        ".config/nacre"
        ".local/state/nacre"
      ];
    }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [nacre.default];

      finit.services.nacre = {
        description = "nacre - bots as holo cards (${userName})";
        user = userName;
        group = "users";
        command = "${waitRuntimeDir} ${start}";
        environment = {
          HOME = user.home;
          XDG_RUNTIME_DIR = runtimeDir;
        };
        path = [
          pkgs.coreutils
          "/run/current-system/sw"
          "/run/wrappers"
          "${user.home}/.nix-profile"
          "${user.home}/.local/state/nix/profile"
          "/nix/var/nix/profiles/default"
        ];
        conditions = ["net/lo/up" "task/persist-user-binds/success"];
        respawn = true;
        log = true;
      };
    })

    (lib.mkIf cfg.app.enable {
      environment.systemPackages = [nacre.desktop];
    })
  ];
}
