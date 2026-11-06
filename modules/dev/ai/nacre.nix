{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  cfg = config.user.dev.nacre;
  inherit (inputPackages) nacre;
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;

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
      default = ["${home}/Tokens/AI_GATEWAY_API_KEY.txt"];
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
      user.persist.directories = [
        ".config/nacre"
        ".local/state/nacre"
      ];
    }

    (lib.mkIf cfg.enable {
      environment.systemPackages = [nacre.default];

      finix.persistence.homeServices = ["nacre"];

      finit.services.nacre = {
        description = "nacre - bots as holo cards (${userName})";
        user = userName;
        group = "users";
        command = "${waitRuntimeDir} ${start}";
        environment = {
          HOME = home;
          XDG_RUNTIME_DIR = runtimeDir;
        };
        path = [
          pkgs.coreutils
          "/run/current-system/sw"
          "/run/wrappers"
          "${home}/.nix-profile"
          "${home}/.local/state/nix/profile"
          "/nix/var/nix/profiles/default"
        ];
        conditions = ["net/lo/up"];
        respawn = true;
        log = true;
      };
    })

    (lib.mkIf cfg.app.enable {
      environment.systemPackages = [nacre.desktop];
    })
  ];
}
