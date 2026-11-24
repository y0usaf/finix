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
  inherit (inputPackages.oh-my-pi) omp;
  lloydConfig = pkgs.writeText "lloyd-advisor.yml" (lib.generators.toYAML {} {advisor.enabled = true;});
  botOmp = pkgs.writeShellScriptBin "omp" ''
    if [ "''${OMP_BOT_NAME-}" = Lloyd ]; then
      exec ${omp}/bin/omp "$@" --config ${lloydConfig}
    fi
    exec ${omp}/bin/omp "$@"
  '';
  src = flakeInputs.omp-bot;
  tools = [pkgs.bun pkgs.jq pkgs.util-linux pkgs.age pkgs.openssh pkgs.gnutar pkgs.bash];
  persistentHome = "/persist/home/${userName}";
  ext = "${home}/.omp/agent/ext";
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
in {
  user.persist = {
    directories = [".local/state/omp-bot"];
    directorySources = [persistPaths];
  };
  environment.systemPackages = [(command "omp-bot") (command "omp-bot-ctl") pkgs.age pkgs.gnutar];

  user.files = {
    ".config/omp-bot/env".text = ''
      : "''${OMP_BIN:=${botOmp}/bin/omp}"
      : "''${OMP_BOT_EXTENSION:=${ext}/crest-auth.ts}"
      : "''${OMP_BOT_CWD_EXTENSION:=${ext}/cwd.ts}"
      : "''${OMP_BOT_SECRETS_EXTENSION:=${ext}/secrets/secrets.ts}"
      : "''${OMP_BOT_WORK_FOLD_EXTENSION:=${ext}/work-fold.ts}"
      : "''${OMP_BOT_CHAT_LOOK_EXTENSION:=${ext}/chat-look.ts}"
      : "''${OMP_BOT_OPTCHAT:=${ext}/optchat}"
      : "''${OMP_BOT_PERSIST:=${persist}}"
      : "''${OMP_BOT_MODEL:=${config.user.dev.modelCatalog.defaultProvider}/${config.user.dev.modelCatalog.defaultModel}}"
    '';
    ".config/tern/plugins/omp-bot.path".text = "${src}/tern\n";
  };
}
