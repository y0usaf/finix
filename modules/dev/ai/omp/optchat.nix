{
  config,
  pkgs,
  inputPackages,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  dir = "${home}/.local/state/optchat";
  inherit (inputPackages.oh-my-pi) omp;

  service = pkgs.writeShellApplication {
    name = "optchat";
    runtimeInputs = [pkgs.coreutils pkgs.jq pkgs.util-linux];
    text = ''
      mkdir -p ${dir}/log
      [ -p ${dir}/optchatd.fifo ] || mkfifo ${dir}/optchatd.fifo
      grant() {
        ${config.system.build.ompBox}/bin/omp-box list --json | jq -e --arg p "$1" 'any(.[]; .path == $p)' >/dev/null \
          || ${config.system.build.ompBox}/bin/omp-box add "$@" || echo "optchat: the box cannot reach $1 yet" >&2
      }
      grant ${dir} --ro
      grant ${dir}/log --name optchat.log
      cd ${dir}
      exec 9>${dir}/optchatd.lock
      flock -n 9 || { echo "optchat: already running (${dir}/optchatd.lock is held)" >&2; exit 1; }
      exec ${omp}/bin/omp --mode rpc --no-ui --no-session --no-extensions --no-tools --no-lsp --no-skills --no-rules --no-title \
        -e ${./optchat}/service.ts <>${dir}/optchatd.fifo >/dev/null
    '';
  };

  spend = pkgs.writeShellApplication {
    name = "optchat-spend";
    runtimeInputs = [pkgs.jq pkgs.util-linux];
    text = ''
      log="''${OPTCHAT_DIR:-$HOME/.local/state/optchat}/spend.jsonl"
      if [ ! -s "$log" ]; then
        echo "optchat: nothing spent yet ($log is empty)"
        exit 0
      fi
      jq -rs '
        def row: [.day, (.calls|tostring), (.input|tostring), (.cached|tostring), (.output|tostring), ("$" + (.usd*10000|round/10000|tostring))] | @tsv;
        def sum: {calls: length, input: (map(.input)|add), cached: (map(.cacheRead)|add), output: (map(.output)|add), usd: (map(.cost)|add)};
        (["day", "calls", "input", "cached", "output", "list price"] | @tsv),
        (group_by(.time/1000|localtime|strftime("%Y-%m-%d"))[] | {day: (.[0].time/1000|localtime|strftime("%Y-%m-%d"))} + sum | row),
        ({day: "total"} + sum | row)
      ' "$log" | column -t -s "$(printf '\t')"
    '';
  };
in {
  user.persist.directories = [".local/state/optchat"];
  finix.persistence.homeServices = ["optchat"];

  environment.systemPackages = [spend];

  finit.services.optchat = {
    description = "OptChat memory shared by omp chats";
    inherit user;
    reload-signal = "none";
    log = true;
    environment = {
      HOME = home;
      XDG_STATE_HOME = "${home}/.local/state";
    };
    command = "${service}/bin/optchat";
  };
}
