{
  config,
  pkgs,
  flakeInputs,
  generators,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  dir = "${home}/.local/state/optchat";
  omp = flakeInputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp;

  service = pkgs.writeShellApplication {
    name = "optchat";
    runtimeInputs = [pkgs.coreutils pkgs.jq];
    text = ''
      mkdir -p ${dir}
      [ -p ${dir}/optchatd.fifo ] || mkfifo ${dir}/optchatd.fifo
      if ! /run/current-system/sw/bin/omp-box list --json | jq -e --arg p ${dir} 'any(.[]; .path == $p)' >/dev/null; then
        /run/current-system/sw/bin/omp-box add ${dir} || echo "optchat: the box cannot reach ${dir} yet" >&2
      fi
      cd ${dir}
      exec ${omp}/bin/omp --mode rpc --no-ui --no-session --no-extensions --no-tools --no-lsp --no-skills --no-rules --no-title \
        -e ${generators.sourceDir pkgs "optchat" (import ./optchat/optchat.data.nix {inherit generators;})}/service.ts <>${dir}/optchatd.fifo >/dev/null
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
  finix.persistence = {
    allowlist.users.${user}.directories = [".local/state/optchat"];
    homeServices = ["optchat"];
  };

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
