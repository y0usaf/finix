{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";
  omp = flakeInputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp;
  src = flakeInputs.omp-bot;
  tools = [pkgs.bun pkgs.jq pkgs.util-linux];
  command = name:
    pkgs.writeShellScriptBin name ''
      PATH=${pkgs.lib.makeBinPath tools}:$PATH exec ${src}/bin/${name} "$@"
    '';
  start = pkgs.writeShellScript "omp-botd-start" ''
    set -eu
    key=${user.home}/Tokens/AI_GATEWAY_API_KEY.txt
    [ ! -r "$key" ] || export AI_GATEWAY_API_KEY="$(cat "$key")"
    exec ${src}/bin/omp-botd
  '';
in {
  finix.persistence = {
    allowlist.users.${userName}.directories = [".local/state/omp-bot"];
    homeServices = ["omp-botd"];
  };

  environment.systemPackages = [(command "omp-bot") (command "omp-bot-ctl")];

  manzil.users.${userName}.files = {
    ".config/omp-bot/env".text = ''
      : "''${OMP_BIN:=${omp}/bin/omp}"
      : "''${OMP_BOT_EXTENSION:=${./omp/crest-auth.ts}}"
      : "''${OMP_BOT_OPTCHAT:=${./omp/optchat}}"
    '';
    ".config/tern/plugins/omp-bot.path".text = "${src}/tern\n";
  };

  finit.services.omp-botd = {
    description = "omp-bot task supervisor (${userName})";
    user = userName;
    group = "users";
    command = "${start}";
    environment = {
      HOME = user.home;
      XDG_RUNTIME_DIR = runtimeDir;
    };
    path = tools ++ [pkgs.coreutils "/run/current-system/sw" "/run/wrappers"];
    respawn = true;
    log = true;
  };
}
