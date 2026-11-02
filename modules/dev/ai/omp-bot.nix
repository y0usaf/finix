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
  start = pkgs.writeShellScript "omp-botd-start" ''
    set -eu
    key=${user.home}/Tokens/AI_GATEWAY_API_KEY.txt
    [ ! -r "$key" ] || export AI_GATEWAY_API_KEY="$(cat "$key")"
    exec ${flakeInputs.omp-bot}/bin/omp-botd
  '';
in {
  finix.persistence = {
    allowlist.users.${userName}.directories = [".local/state/omp-bot"];
    homeServices = ["omp-botd"];
  };

  finit.services.omp-botd = {
    description = "omp-bot task supervisor (${userName})";
    user = userName;
    group = "users";
    command = "${start}";
    environment = {
      HOME = user.home;
      XDG_RUNTIME_DIR = runtimeDir;
      OMP_BIN = "${omp}/bin/omp";
    };
    path = [
      pkgs.bun
      pkgs.jq
      pkgs.util-linux
      pkgs.coreutils
      "/run/current-system/sw"
      "/run/wrappers"
    ];
    respawn = true;
    log = true;
  };
}
