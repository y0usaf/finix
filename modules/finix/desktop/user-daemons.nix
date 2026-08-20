# Desktop user daemons as supervised finit services running as y0usaf (no
# systemd user sessions). Restores pre-existing gaps the compat shim dropped:
#   - ssh-agent: the ssh module (modules/user-services/ssh.nix) exports
#     SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"; this is the agent backing it.
#   - udiskie --automount: automounts removable media via the udisks2 that
#     parity.nix enables (services.udisks2.enable = true).
#
# Same finit pattern as paseo/audio: real user, explicit HOME + XDG_RUNTIME_DIR,
# wait for the boot-created runtime dir (the xdg-runtime-dir task in
# session.nix owns /run/user/1001) before exec'ing, log to syslog.
{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  user = config.users.users.${userName};
  runtimeDir = "/run/user/${toString user.uid}";
  home = user.home;
  svcEnv = {
    HOME = home;
    XDG_RUNTIME_DIR = runtimeDir;
  };

  # finix boots into runlevel 2 (see session.nix seatd note); wait for the
  # runtime dir, then become the daemon. finit restarts us if it never shows.
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
    # ssh-agent: -D = foreground (supervised), -a pins the socket to
    # $XDG_RUNTIME_DIR/ssh-agent exactly where modules/user-services/ssh.nix
    # points SSH_AUTH_SOCK. No conditions other than the runtime dir: the
    # agent is useful even without network.
    ssh-agent = {
      description = "ssh-agent (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${waitRuntimeDir} ${pkgs.openssh}/bin/ssh-agent -D -a ${runtimeDir}/ssh-agent";
      log = true;
    };

    # Talks to udisks2 over the system bus; no session bus required.
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
