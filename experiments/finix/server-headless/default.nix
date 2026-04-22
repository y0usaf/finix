{
  inputs,
  system,
}: let
  pkgs = import inputs.nixpkgs {
    inherit system;
  };
  inherit (pkgs) lib;

  finixModules = import "${inputs.finix.outPath}/modules";
  allFinixModules = builtins.attrValues (builtins.removeAttrs finixModules ["default"]);

  persistUuid = "9dfc38c4-5c75-471d-9106-80ff9175ab92";
  bootUuid = "41B0-E342";
  trialIp = "192.168.2.66/24";
  trialGateway = "192.168.2.1";

  trialSystem = inputs.finix.lib.finixSystem {
    inherit lib;
    modules =
      allFinixModules
      ++ [
        ({config, ...}: let
          tailscaledStart = pkgs.writeShellScript "tailscaled-start" ''
            exec ${pkgs.tailscale}/bin/tailscaled \
              --state=/persist/var/lib/tailscale/tailscaled.state \
              --socket=/run/tailscale/tailscaled.sock \
              --port=41641
          '';

          watchdogKeepalive = pkgs.writeShellScript "finix-watchdog-keepalive" ''
            set -eu
            dev=/dev/watchdog0

            if ! [ -c "$dev" ]; then
              echo "finix-trial: missing $dev" >&2
              exit 1
            fi

            exec 3>"$dev"
            while true; do
              printf '\0' >&3 || exit 1
              sleep 5
            done
          '';

          networkSetup = pkgs.writeShellScript "finix-network-setup" ''
            set -eu
            iface=""

            for _ in $(seq 1 40); do
              for candidate in enp1s0 eth0; do
                if ${pkgs.iproute2}/bin/ip link show "$candidate" >/dev/null 2>&1; then
                  iface="$candidate"
                  break
                fi
              done

              if [ -n "$iface" ]; then
                break
              fi

              sleep 1
            done

            if [ -z "$iface" ]; then
              echo "finix-trial: no usable interface" >&2
              exit 1
            fi

            ${pkgs.iproute2}/bin/ip link set "$iface" up
            ${pkgs.iproute2}/bin/ip addr replace ${trialIp} dev "$iface"
            ${pkgs.iproute2}/bin/ip route replace default via ${trialGateway} dev "$iface"
            printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf
            printf '%s\n' "$iface" > /run/finix-trial/iface
          '';

          trialMarker = pkgs.writeShellScript "finix-trial-marker" ''
            set -eu
            mkdir -p /persist/finix-trial
            boot_id=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)
            {
              echo "time=$(date -Is)"
              echo "boot_id=$boot_id"
              echo "pid1=$(cat /proc/1/comm 2>/dev/null || true)"
              echo "iface=$(cat /run/finix-trial/iface 2>/dev/null || echo unknown)"
              ${pkgs.iproute2}/bin/ip -4 -br addr || true
              ${pkgs.findutils}/bin/findmnt -no TARGET,SOURCE,FSTYPE / /nix /persist || true
            } > /persist/finix-trial/last-boot.txt
          '';

          autoReturn = pkgs.writeShellScript "finix-auto-return" ''
            sleep 180
            if [ -e /persist/finix-trial/boot-ok ]; then
              exit 0
            fi
            exec ${config.finit.package}/bin/initctl reboot
          '';

          nftablesConfig = pkgs.writeText "finix-trial-nftables.conf" ''
            flush ruleset

            table inet filter {
              chain input {
                type filter hook input priority 0;
                policy drop;

                iifname lo accept
                ct state established,related accept
                ip protocol icmp accept
                ip6 nexthdr ipv6-icmp accept

                tcp dport { 22 } accept
                udp dport { 41641 } accept
              }

              chain forward {
                type filter hook forward priority 0;
                policy drop;
              }

              chain output {
                type filter hook output priority 0;
                policy accept;
              }
            }
          '';
        in {
          nixpkgs.pkgs = pkgs;

          boot = {
            initrd = {
              availableKernelModules = ["xhci_pci" "ahci" "sd_mod"];
              kernelModules = [];
            };
            kernelModules = ["btrfs" "r8169" "tun"];
            kernel.sysctl."vm.swappiness" = 100;
          };

          fileSystems = {
            "/" = {
              device = "none";
              fsType = "tmpfs";
              options = ["mode=755" "size=1G"];
            };

            "/nix" = {
              device = "/dev/disk/by-uuid/${persistUuid}";
              fsType = "btrfs";
              options = ["subvol=@nix" "compress=zstd" "noatime"];
            };

            "/persist" = {
              device = "/dev/disk/by-uuid/${persistUuid}";
              fsType = "btrfs";
              options = ["subvol=@persist" "compress=zstd" "noatime"];
              neededForBoot = true;
            };

            "/boot" = {
              device = "/dev/disk/by-uuid/${bootUuid}";
              fsType = "vfat";
              options = ["fmask=0022" "dmask=0022"];
            };
          };

          swapDevices = [];

          networking.hostName = "y0usaf-server";

          services.mdevd.enable = true;
          services.sysklogd.enable = true;
          services.nftables = {
            enable = true;
            configFile = nftablesConfig;
          };
          services.openssh = {
            enable = true;
            settings = {
              PasswordAuthentication = false;
              PermitRootLogin = "no";
              KbdInteractiveAuthentication = false;
              AuthorizedKeysFile = [
                ".ssh/authorized_keys"
                "Tokens/authorized_keys"
                "/persist/etc/ssh/authorized_keys.d/%u"
              ];
              HostKey = [
                "/persist/etc/ssh/ssh_host_ed25519_key"
                "/persist/etc/ssh/ssh_host_rsa_key"
              ];
            };
          };

          programs.sudo.enable = true;
          environment.etc.sudoers.text = lib.mkAfter ''
            y0usaf ALL = (ALL:ALL) NOPASSWD: ALL
          '';

          environment.systemPackages = with pkgs; [
            bashInteractive
            findutils
            iproute2
            iputils
            jq
            procps
            tailscale
            util-linux
          ];

          system.activation.scripts.finixTrialMachineId = {
            deps = ["etc" "users"];
            text = ''
              mkdir -p /persist/finix-trial
              rm -f /persist/finix-trial/boot-ok
              if [ -s /persist/etc/machine-id ]; then
                rm -f /etc/machine-id
                ln -sfn /persist/etc/machine-id /etc/machine-id
              fi
            '';
          };

          users.users.y0usaf = {
            isNormalUser = true;
            home = "/home/y0usaf";
            shell = "${pkgs.bashInteractive}/bin/bash";
            extraGroups = ["wheel"];
          };

          finit.tmpfiles.rules = [
            "d /run/tailscale 0755 root root"
            "d /home 0755 root root"
            "d /home/y0usaf 0700 y0usaf users"
            "d /run/finix-trial 0755 root root"
            "d /persist/finix-trial 0755 root root"
          ];

          finit.tasks.finix-trial-network = {
            description = "trial network setup";
            command = "${networkSetup}";
            remain = true;
            log = true;
            path = [pkgs.iproute2];
          };

          finit.tasks.finix-trial-marker = {
            description = "trial boot marker";
            command = "${trialMarker}";
            conditions = ["task/finix-trial-network/success"];
            remain = true;
            log = true;
            path = [pkgs.findutils pkgs.iproute2];
          };

          finit.services.tailscaled = {
            description = "tailscale daemon";
            command = "${tailscaledStart}";
            conditions = ["service/syslogd/ready" "net/lo/up"];
            log = true;
            path = [pkgs.tailscale];
          };

          finit.services.finix-trial-watchdog = {
            description = "trial watchdog keepalive";
            command = "${watchdogKeepalive}";
            log = true;
          };

          finit.services.finix-trial-auto-return = {
            description = "trial auto return to nixos";
            command = "${autoReturn}";
            conditions = ["task/finix-trial-marker/success"];
            log = true;
          };
        })
      ];
  };

  remoteTrialScript = pkgs.writeShellScriptBin "run-finix-server-headless-trial" ''
        set -euo pipefail

        host="''${1:-server}"
        system_path='${trialSystem.config.system.topLevel}'
        bootjson="$system_path/boot.json"

        kernel="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernel' "$bootjson")"
        initrd="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].initrd' "$bootjson")"
        init="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].init' "$bootjson")"
        kernel_params="$(${pkgs.jq}/bin/jq -r '.["org.nixos.bootspec.v1"].kernelParams | join(" ")' "$bootjson")"
        cmdline="init=$init $kernel_params"

        ${pkgs.nix}/bin/nix copy --to "ssh://$host" "$system_path"

        ${pkgs.openssh}/bin/ssh -o BatchMode=yes "$host" "sudo bash -s -- '$kernel' '$initrd' '$cmdline'" <<'EOF'
    set -euo pipefail
    kernel="$1"
    initrd="$2"
    cmdline="$3"

    if ! [ -c /dev/watchdog0 ]; then
      echo missing:/dev/watchdog0 >&2
      exit 1
    fi

    ( exec 3>/dev/watchdog0; while true; do printf '\0' >&3; sleep 5; done ) &
    kexec -l "$kernel" --initrd="$initrd" --command-line="$cmdline"
    sync
    systemctl kexec
    EOF
  '';
in {
  inherit trialSystem;
  package = trialSystem.config.system.topLevel;
  remoteTrialPackage = remoteTrialScript;
}
