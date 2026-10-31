{
  config,
  pkgs,
  flakeInputs,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  uid = config.users.users.${user}.uid;
  state = "${home}/.local/state/omp-box";
in {
  finix.persistence.allowlist.users.${user}.directories = [".local/state/omp-box"];

  finit.services.omp-box = {
    description = "omp NixOS microVM";
    user = user;
    reload-signal = "none";
    environment = {
      HOME = home;
      XDG_RUNTIME_DIR = "/run/user/${toString uid}";
    };
    command = "${pkgs.writeShellScript "omp-box-run" ''
      mkdir -p ${state}
      cd ${state}
      exec ${flakeInputs.self.packages.${pkgs.stdenv.hostPlatform.system}.omp-box-runner}/bin/microvm-run
    ''}";
  };
}
