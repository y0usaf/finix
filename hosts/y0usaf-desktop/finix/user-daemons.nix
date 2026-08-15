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
  # /run/user/1001 — must match session.nix's task and the pipewire svcEnv.
  runtimeDir = "/run/user/1001";
  home = "/home/y0usaf";
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
      description = "ssh-agent (y0usaf)";
      user = "y0usaf";
      environment = svcEnv;
      command = "${waitRuntimeDir} ${pkgs.openssh}/bin/ssh-agent -D -a ${runtimeDir}/ssh-agent";
      log = true;
    };

    # udiskie: --automount mounts removable media as the persistent user.
    # Talks to udisks2 over the system bus (parity.nix enables it). No
    # dbus session bus needed for --automount (it uses the system udisks2).
    udiskie = {
      description = "udiskie automount (y0usaf)";
      user = "y0usaf";
      environment = svcEnv;
      command = "${waitRuntimeDir} ${pkgs.udiskie}/bin/udiskie --automount";
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
