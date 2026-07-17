# SSH deploy driver: config-only changes to a running persistent finix
# system. Kernel/initrd/cmdline changes go through the ESP island driver
# (install → oneshot → promote) instead.
{pkgs}: {
  # mkDeploy {name, system, defaultHost}
  mkDeploy = {
    name,
    system,
    defaultHost,
  }: {
    deployScript = pkgs.writeShellScriptBin name ''
      set -euo pipefail

      host="''${1:-${defaultHost}}"
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
          echo "usage: ${name} [host] [test|boot|switch]" >&2
          exit 2
          ;;
      esac

      system_path='${system}'

      if [ "$host" = local ]; then
        # Self-deploy: only meaningful on a running finix system. Under
        # systemd/NixOS the activation would clobber the live /etc.
        if [ -d /run/systemd/system ]; then
          echo "${name}: refusing local $action under systemd/NixOS; boot finix first (or target a host over ssh)" >&2
          exit 1
        fi
        sudo "$system_path/sw/bin/nix-store" --realise "$system_path" \
          --add-root /nix/var/nix/gcroots/finix-persistent >/dev/null
        exec sudo "$system_path/bin/switch-to-configuration" "$action"
      fi

      # Keep this independent of the active Finix system: the NixOS system
      # profile on the shared @nix subvolume supplies nix-store even during
      # the first deployment from a trial boot.
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
  };
}
