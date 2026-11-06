{
  lib,
  pkgs,
  ...
}: let
  home = "/var/lib/amp-orb";
  tokenFile = "${home}/provider-token";
  env = {
    HOME = home;
    XDG_RUNTIME_DIR = "/run/amp-orb";
    TMPDIR = "${home}/tmp";
  };
  podman = "${lib.getExe pkgs.podman} --log-level=error";

  dispatch = pkgs.writeShellScript "amp-orb-dispatch" ''
    set -eu
    case "$ORB_OPERATION" in
      spawn)
        if ! ${podman} container exists "$ORB_ID"; then
          image=$ORB_IMAGE pull=newer
          if [ -n "''${ORB_SNAPSHOT_ID-}" ] && ${podman} image exists "$ORB_SNAPSHOT_ID"; then
            image=$ORB_SNAPSHOT_ID pull=never
          fi
          ${podman} create --quiet --init --pull "$pull" --name "$ORB_ID" "$image" sleep infinity >/dev/null
        fi
        ${podman} start "$ORB_ID" >/dev/null
        ${podman} exec --detach --env ORB_TOKEN ''${AMP_URL:+--env AMP_URL} "$ORB_ID" amp orb bootstrap >/dev/null
        ;;
      pause)
        ${podman} stop --ignore "$ORB_ID" >/dev/null
        if [ -n "''${ORB_SNAPSHOT_ID-}" ]; then
          ${podman} commit --quiet "$ORB_ID" "$ORB_SNAPSHOT_ID" >/dev/null
        fi
        ;;
      delete)
        ${podman} rm --force --ignore "$ORB_ID" >/dev/null
        ${podman} image prune --force >/dev/null
        ;;
      *)
        echo "amp-orb-dispatch: unknown ORB_OPERATION '$ORB_OPERATION'" >&2
        exit 1
        ;;
    esac
  '';
in {
  imports = [../core/podman.nix];

  users = {
    users.amp-orb = {
      isSystemUser = true;
      uid = 420;
      group = "amp-orb";
      inherit home;
      createHome = true;
    };
    groups.amp-orb.gid = 420;
  };

  environment = {
    etc = {
      "subuid".text = "amp-orb:165536:65536\n";
      "subgid".text = "amp-orb:165536:65536\n";
    };

    systemPackages = [
      (pkgs.writeShellScriptBin "amp-orb-podman" ''
        cd /
        exec sudo -u amp-orb ${lib.concatStringsSep " " (lib.mapAttrsToList (n: v: "${n}=${v}") env)} PATH=/run/wrappers/bin ${podman} "$@"
      '')
    ];
  };

  fileSystems.${home} = {
    device = "/persist${home}";
    fsType = "btrfs";
    options = ["bind"];
    neededForBoot = true;
  };

  finit = {
    tmpfiles.rules = [
      "d /persist${home} 0700 amp-orb amp-orb"
      "d ${env.XDG_RUNTIME_DIR} 0700 amp-orb amp-orb"
      "d ${env.TMPDIR} 0700 amp-orb amp-orb"
    ];

    services.amp-orb = {
      description = "Amp self-hosted orb provider";
      user = "amp-orb";
      group = "amp-orb";
      environment = env;
      path = [pkgs.coreutils pkgs.util-linux "/run/wrappers"];
      command = pkgs.writeShellScript "amp-orb-provider" ''
        set -eu
        mountpoint -q ${home} || {
          echo "amp-orb: ${home} is not mounted from /persist; refusing to fill the root tmpfs" >&2
          exit 1
        }
        [ -s ${tokenFile} ] || {
          echo "amp-orb: no provider token in ${tokenFile}" >&2
          exit 1
        }
        AMP_ORB_PROVIDER_TOKEN=$(cat ${tokenFile})
        export AMP_ORB_PROVIDER_TOKEN
        exec ${lib.getExe pkgs.amp-cli} orb provider ${dispatch}
      '';
      nohup = true;
      log = true;
    };
  };
}
