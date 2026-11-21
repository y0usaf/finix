{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  mintPkg = inputPackages.mint.default;
  user = config.user.name;
  home = config.user.homeDirectory;
  inherit (config.user) runtimeDir;
  stateDir = "${home}/.local/state/mint";
  keyPath = "${stateDir}/cdp_key.json";
  heartbeatDir = "${home}/.local/state/omp-bot/bots/Mint/heartbeat";
  socket = "${runtimeDir}/mint-execd.sock";
  port = 9402;

  launcher = pkgs.writeShellScript "mint-execd-launch" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    mkdir -p -m 0700 ${lib.escapeShellArg stateDir} ${lib.escapeShellArg heartbeatDir}
    chmod 0700 ${lib.escapeShellArg stateDir} ${lib.escapeShellArg heartbeatDir}
    trap 'exit 0' TERM INT
    while [ ! -s ${lib.escapeShellArg keyPath} ]; do
      sleep 10 &
      wait $! || exit 0
    done
    exec ${mintPkg}/bin/mint-execd
  '';
in {
  environment = {
    systemPackages = [mintPkg];
    variables.MINT_CTL_SOCKET = socket;
  };

  finix.persistence.homeServices = ["mint-execd"];

  user = {
    persist.directories = [".local/state/mint"];
    dev.ompBoxHostServices.Mint.ports = [port];
  };

  finit.services.mint-execd = {
    description = "Mint Coinbase spot execution daemon";
    inherit user;
    group = "users";
    reload-signal = "none";
    respawn = true;
    restart-sec = 5;
    log = true;
    conditions = ["task/tmpfiles-setup/success" "service/auth-router/running"];
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = runtimeDir;
      MINT_STATE_DIR = stateDir;
      MINT_KEY_PATH = keyPath;
      MINT_POLICY_PATH = "${stateDir}/policy.json";
      MINT_HEARTBEAT_DIR = heartbeatDir;
      MINT_LISTEN = "127.0.0.1:${toString port}";
      MINT_CTL_SOCKET = socket;
      MINT_ATOP_CMD = "${inputPackages.auth-router.default}/bin/atop";
      AUTH_ROUTER_SOCKET = "${runtimeDir}/auth-router.sock";
    };
    command = "${launcher}";
  };
}
