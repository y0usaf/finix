{
  config,
  lib,
  pkgs,
  flakeInputs,
  inputPackages,
  ...
}: let
  userName = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  inherit (inputPackages.oh-my-pi) omp;
  pilotConfig = pkgs.writeText "lloyd-python.yml" (lib.generators.toYAML {} {
    python.interpreter = "${pkgs.python3.withPackages (ps: [ps.pillow])}/bin/python3";
  });
  pilotOmp = pkgs.writeShellScriptBin "omp" ''
    if [ "''${OMP_BOT_NAME-}" = Lloyd ]; then
      export OMP_BOT_PREWALK="''${OMP_BOT_PREWALK-1}"
      export OMP_BOT_MAX_HELPERS="''${OMP_BOT_MAX_HELPERS-16}"
      exec ${omp}/bin/omp --config ${pilotConfig} "$@"
    fi
    exec ${omp}/bin/omp "$@"
  '';
  src = flakeInputs.omp-bot;
  tools = [pkgs.bun pkgs.jq pkgs.util-linux pkgs.age pkgs.openssh pkgs.gnutar pkgs.bash];
  persistentHome = "/persist/home/${userName}";
  # The links to omp's extensions the ai_omp module keeps, named the same as in its config.yml, so a bot with
  # "extensions": true loads each once and a switch shows a running bot no new extension path.
  ext = "${home}/.omp/agent/ext";
  # Prints the persist paths of every bot on the persisted roster, relative to home, for persist-user-binds.
  persistPaths = pkgs.writeShellScript "omp-bot-persist-paths" ''
    roster=${persistentHome}/.local/state/omp-bot/bots.json
    [ -r "$roster" ] || exit 0
    ${pkgs.jq}/bin/jq -r '.[] | objects | .persist | arrays | .[] | strings' "$roster" | while IFS= read -r path; do
      case $path in
        "~/"?*) printf '%s\n' "''${path#"~/"}" ;;
        ${home}/?*) printf '%s\n' "''${path#${home}/}" ;;
        *) echo "omp-bot-persist-paths: $path is not inside ${home}, so it is not persisted" >&2 ;;
      esac
    done
  '';
  # bin/omp-bot's OMP_BOT_PERSIST hook. mount PATH: keep PATH in ${persistentHome} from now on, copying
  # what it holds the first time, and bind it over PATH (persist-user-binds does it at boot). purge PATH:
  # unmount it and delete both copies, only ever called by omp-bot-remove --purge.
  persist = pkgs.writeShellScript "omp-bot-persist" ''
    set -euo pipefail
    export PATH=${pkgs.lib.makeBinPath [pkgs.coreutils pkgs.util-linux]}:$PATH
    usage="usage: omp-bot-persist mount|purge PATH..."
    [ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }
    cmd=$1
    shift
    for path in "$@"; do
      case $path in
        ${home}/?*) relative=''${path#${home}/} ;;
        *) echo "omp-bot-persist: $path is not inside ${home}" >&2; exit 1 ;;
      esac
      case "/$relative/" in
        */../* | */./* | *//*) echo "omp-bot-persist: $path is not a plain path" >&2; exit 1 ;;
      esac
      src=${persistentHome}/$relative
      case $cmd in
        mount)
          mountpoint -q "$path" && continue
          if [ ! -d "$src" ]; then
            mkdir -p "$(dirname "$src")"
            rm -rf "$src.new"
            if [ -d "$path" ]; then cp -a "$path" "$src.new"; else mkdir "$src.new"; fi
            mv "$src.new" "$src"
          elif [ -n "$(ls -A "$path" 2>/dev/null)" ]; then
            echo "omp-bot-persist: $src already holds $path; mounting it over what $path gained since boot" >&2
          fi
          mkdir -p "$path"
          /run/wrappers/bin/sudo -n mount --bind "$src" "$path"
          echo "$path"
          ;;
        purge)
          while mountpoint -q "$path"; do /run/wrappers/bin/sudo -n umount "$path"; done
          rm -rf -- "$src" "$path"
          ;;
        *) echo "$usage" >&2; exit 2 ;;
      esac
    done
  '';
  command = name:
    pkgs.writeShellScriptBin name ''
      PATH=${pkgs.lib.makeBinPath tools}:$PATH exec ${src}/bin/${name} "$@"
    '';
  start = pkgs.writeShellScript "omp-botd-start" ''
    set -euo pipefail
    key=${home}/Tokens/AI_GATEWAY_API_KEY.txt
    if [ -r "$key" ]; then
      AI_GATEWAY_API_KEY=$(${pkgs.coreutils}/bin/cat "$key") || { echo "omp-botd: cannot read $key" >&2; exit 1; }
      export AI_GATEWAY_API_KEY
    fi
    exec ${src}/bin/omp-botd
  '';
  ompd = pkgs.writeShellScript "ompd-start" ''
    set -euo pipefail
    logs=${home}/.local/state/omp-bot/logs
    ${pkgs.coreutils}/bin/mkdir -p "$logs" || { echo "ompd: cannot create $logs" >&2; exit 1; }
    exec ${src}/bin/ompd serve --wait >>"$logs/ompd.log" 2>&1
  '';
in {
  user.persist = {
    directories = [".local/state/omp-bot"];
    directorySources = [persistPaths];
  };
  finix.persistence.homeServices = ["omp-botd" "ompd"];

  environment.systemPackages = [(command "omp-bot") (command "omp-bot-ctl") pkgs.age pkgs.gnutar];

  user.files = {
    ".config/omp-bot/env".text = ''
      : "''${OMP_BIN:=${pilotOmp}/bin/omp}"
      : "''${OMP_BOT_EXTENSION:=${ext}/crest-auth.ts}"
      : "''${OMP_BOT_CWD_EXTENSION:=${ext}/cwd.ts}"
      : "''${OMP_BOT_SECRETS_EXTENSION:=${ext}/secrets/secrets.ts}"
      : "''${OMP_BOT_WORK_FOLD_EXTENSION:=${ext}/work-fold.ts}"
      : "''${OMP_BOT_CHAT_LOOK_EXTENSION:=${ext}/chat-look.ts}"
      : "''${OMP_BOT_OMPD_EXTENSION:=${ext}/omp-bot/omp/ompd.ts}"
      : "''${OMP_BOT_OPTCHAT:=${ext}/optchat}"
      export OMPD_SERVICE="''${OMPD_SERVICE-1}"
      : "''${OMP_BOT_PERSIST:=${persist}}"
    '';
    ".config/tern/plugins/omp-bot.path".text = "${src}/tern\n";
  };

  finit.services.omp-botd = {
    description = "omp-bot task supervisor (${userName})";
    user = userName;
    group = "users";
    command = "${start}";
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
    };
    path = lib.mkMerge [(tools ++ [pkgs.coreutils]) (lib.mkAfter ["/run/current-system/sw" "/run/wrappers"])];
    respawn = true;
    stop-timeout = 130;
    log = true;
  };

  finit.services.ompd = {
    description = "omp-bot job daemon (${userName})";
    user = userName;
    group = "users";
    command = "${ompd}";
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
    };
    path = lib.mkMerge [(tools ++ [pkgs.coreutils]) (lib.mkAfter ["/run/current-system/sw" "/run/wrappers"])];
    cgroup.system.delegate = true;
    respawn = true;
    log = true;
  };
}
