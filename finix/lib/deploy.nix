# SSH deploy driver: config-only changes to the running persistent system.
{
  pkgs,
  serverPersistent,
}: {
  persistentDeployScript = pkgs.writeShellScriptBin "finix-server-persistent-deploy" ''
    set -euo pipefail

    host="''${1:-server}"
    action="''${2:-test}"
    case "$host" in
      *[!A-Za-z0-9_.:@-]*)
        echo "invalid host: $host" >&2
        exit 2
        ;;
    esac
    case "$action" in
      test|boot|switch) ;;
      *)
        echo "usage: finix-server-persistent-deploy [host] [test|boot|switch]" >&2
        exit 2
        ;;
    esac

    system_path='${serverPersistent.config.system.topLevel}'
    # Keep this independent of the active Finix system: the NixOS system
    # profile on the shared @nix subvolume supplies nix-store even during the
    # first deployment from a trial boot.
    remote_store="ssh://$host?remote-program=/nix/var/nix/profiles/system/sw/bin/nix-store"

    echo "==> copying persistent finix closure to $host"
    nix copy --to "$remote_store" "$system_path"

    echo "==> rooting persistent closure"
    ssh "$host" \
      "/run/wrappers/bin/sudo '$system_path/sw/bin/nix-store' --realise '$system_path' --add-root /nix/var/nix/gcroots/finix-persistent"

    echo "==> finix switch-to-configuration $action"
    ssh "$host" \
      "/run/wrappers/bin/sudo '$system_path/bin/switch-to-configuration' '$action'"
  '';
}
