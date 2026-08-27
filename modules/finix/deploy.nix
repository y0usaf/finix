# SSH deploy driver for a running persistent Finix system. The server's
# kernel/initrd/cmdline changes use the separate ESP island driver; desktop
# bootloader updates are handled by its Limine module.
{lib, pkgs}: {
  # mkDeploy {name, system, defaultHost, ...}
  mkDeploy = {
    bootDriverName ? null,
    defaultHost,
    name,
    system,
    sshHost ? null,
    sshPort ? null,
  }: let
    # Precomputed interpolations for the shell script below; empty when unset.
    bootDriver = lib.optionalString (bootDriverName != null) bootDriverName;
    portStr = lib.optionalString (sshPort != null) (toString sshPort);
    portOpt = lib.optionalString (sshPort != null) ":${toString sshPort}";
  in {
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
      if [ "$action" = boot ] && [ -n '${bootDriver}' ]; then
        echo "${name}: 'boot' cannot stage a boot slot on this host (stc has no bootloader here)." >&2
        echo "  use: ${bootDriver} install, then oneshot, then promote" >&2
        exit 1
      fi

      system_path='${system}'
      remote_host="${
        if sshHost == null
        then "$host"
        else sshHost
      }"

      if [ "$host" != local ] && [ -n '${portStr}' ]; then
        export NIX_SSHOPTS='-p ${portStr} -o ControlPath=none'
        ssh_cmd=(ssh -p '${portStr}' -o ControlPath=none)
      else
        ssh_cmd=(ssh)
      fi

      if [ "$host" = local ]; then
        # Self-deploy only runs on a live Finix system. Refuse systemd hosts
        # because their activation model is different.
        if [ -d /run/systemd/system ]; then
          echo "${name}: refusing local $action under systemd; target a live Finix host over ssh" >&2
          exit 1
        fi
        sudo "$system_path/sw/bin/nix-store" --realise "$system_path" \
          --add-root /nix/var/nix/gcroots/finix-persistent >/dev/null
        if [ "$action" != test ]; then
          sudo "$system_path/sw/bin/nix-env" -p /nix/var/nix/profiles/system --set "$system_path"
        fi
        sudo "$system_path/bin/switch-to-configuration" "$action"
        exit 0
      fi

      # The running Finix system supplies the remote nix-store endpoint.
      remote_store="ssh://$remote_host${portOpt}?remote-program=/run/current-system/sw/bin/nix-store"

      echo "==> copying persistent finix closure to $remote_host"
      nix copy --to "$remote_store" "$system_path"

      echo "==> rooting persistent closure"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/sw/bin/nix-store' --realise '$system_path' --add-root /nix/var/nix/gcroots/finix-persistent"

      if [ "$action" != test ]; then
        echo "==> registering system profile generation"
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/nix-env -p /nix/var/nix/profiles/system --set '$system_path'"
      fi

      echo "==> finix switch-to-configuration $action"
      "''${ssh_cmd[@]}" "$remote_host" \
        "/run/wrappers/bin/sudo '$system_path/bin/switch-to-configuration' '$action'"
      # Flush filesystem and bootloader writes before returning control.
      if [ "$action" != test ]; then
        "''${ssh_cmd[@]}" "$remote_host" \
          "/run/wrappers/bin/sudo /run/current-system/sw/bin/sync"
      fi
    '';
  };
}
