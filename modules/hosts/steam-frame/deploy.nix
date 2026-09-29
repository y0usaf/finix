{
  inputs,
  pkgs,
}: let
  toplevel = pkgs.writeText "steam-frame-toplevel.nix" ''
    {repo}:
    let
      config = ((builtins.getFlake ("path:" + repo)).nixosConfigurations.frame.extendModules {
        specialArgs.boloPackages = (builtins.getFlake "path:${inputs.bolo}").packages.aarch64-linux;
        modules = [
          "${inputs.manzil}/nix/modules/nixos.nix"
          "${inputs.self}/modules/hosts/steam-frame/config.nix"
          {manzil.linker = (builtins.getFlake "path:${inputs.manzil}").packages.x86_64-linux.manzil-aarch64-linux-static;}
        ];
      }).config;
    in {
      toplevel = config.system.build.toplevel;
      rootUuid = config.frame.storage.poolUuid;
    }
  '';
in
  pkgs.writeShellScriptBin "finix-frame-deploy" ''
    set -euo pipefail

    host="''${1:-frame-nixos.home}"
    repo="''${FRAME_REPO:-/home/y0usaf/dev/maintaining/steam-frame-nixos}"
    case "$host" in
      *[!A-Za-z0-9_.:@-]*)
        echo "invalid host: $host" >&2
        exit 2
        ;;
    esac

    qemu=$(${pkgs.gawk}/bin/awk '$1 == "interpreter" { print $2 }' /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null || true)
    if [ -z "$qemu" ]; then
      echo "finix-frame-deploy: qemu-aarch64 binfmt is not registered; run: sudo $repo/tools/binfmt.sh" >&2
      exit 1
    fi

    system=$(nix build --no-link --print-out-paths --impure \
      --option extra-platforms aarch64-linux \
      --option extra-sandbox-paths "''${qemu%/bin/*}" \
      --file ${toplevel} --argstr repo "$repo" toplevel)
    rootUuid=$(nix eval --raw --impure --file ${toplevel} --argstr repo "$repo" rootUuid)

    ssh_opts=(-i "$HOME/.ssh/id_rsa_frame" -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=error -o ConnectTimeout=10 -o ControlMaster=no -o ControlPath=none)
    rootState=$(ssh "''${ssh_opts[@]}" "root@$host" "findmnt -n -r -o UUID,FSROOT -T /")
    if [ "$rootState" != "$rootUuid /@root" ]; then
      echo "finix-frame-deploy: refusing deployment from root $rootState; expected $rootUuid /@root. Boot the shared pool first." >&2
      exit 1
    fi
    NIX_SSHOPTS="''${ssh_opts[*]}" nix copy --no-check-sigs --to "ssh-ng://root@$host" "$system"
    ssh "''${ssh_opts[@]}" "root@$host" "set -e
    nix-env -p /nix/var/nix/profiles/system --set $system
    nix-env -p /nix/var/nix/profiles/system --delete-generations +3 >/dev/null
    systemd-run --collect --no-ask-password --pipe --quiet --service-type=exec --unit=frame-switch -- $system/bin/switch-to-configuration switch >&2
    nix-collect-garbage >/dev/null 2>&1"
    echo "$system"
  ''
