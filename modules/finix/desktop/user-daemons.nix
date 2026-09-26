{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";
  inherit (user) home;
  svcEnv = {
    HOME = home;
    XDG_RUNTIME_DIR = runtimeDir;
  };

  waitRuntimeDir = pkgs.writeShellScript "wait-user-daemon-runtime" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    for _ in $(seq 1 60); do
      [ -d ${runtimeDir} ] && exec "$@"
      sleep 1
    done
    echo "wait-user-daemon-runtime: ${runtimeDir} never appeared" >&2
    exit 1
  '';
in {
  environment.systemPackages = [
    pkgs.udiskie
  ];

  finit.services = {
    ssh-agent = {
      description = "ssh-agent (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${waitRuntimeDir} ${pkgs.openssh}/bin/ssh-agent -D -a ${runtimeDir}/ssh-agent";
      log = true;
    };

    udiskie = {
      description = "udiskie automount (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${waitRuntimeDir} ${pkgs.udiskie}/bin/udiskie --automount";
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
