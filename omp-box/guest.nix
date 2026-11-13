{
  lib,
  pkgs,
  ompBox,
  ...
}: let
  inherit (ompBox) user;
  home = "/home/${user}";
  # Headless Chromium says HeadlessChrome in its user agent, which shops turn away; claim the same version as Chrome.
  userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${lib.versions.major pkgs.ungoogled-chromium.version}.0.0.0 Safari/537.36";
  browser = name: {
    profile,
    port,
  }: {
    description = "Chromium on a virtual screen for ${name}, DevTools on 127.0.0.1:${toString port}";
    wantedBy = ["multi-user.target"];
    startLimitIntervalSec = 0;
    environment.HOME = home;
    serviceConfig = {
      User = user;
      Group = "users";
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      profile=${lib.escapeShellArg profile}
      if [ "$(${pkgs.util-linux}/bin/findmnt -n -o FSTYPE --target "$(dirname "$profile")")" != 9p ]; then
        echo "$(dirname "$profile") is not shared into the box yet"
        exit 1
      fi
      mkdir -p "$profile"
      rm -f "$profile/SingletonLock" "$profile/SingletonCookie" "$profile/SingletonSocket"
      display=$((${toString port} - 9200))
      rm -f "/tmp/.X$display-lock" "/tmp/.X11-unix/X$display"
      ${pkgs.xvfb}/bin/Xvfb ":$display" -screen 0 1920x1080x24 -nolisten tcp &
      while [ ! -e "/tmp/.X11-unix/X$display" ]; do sleep 0.1; done
      export DISPLAY=":$display"
      exec ${pkgs.ungoogled-chromium}/bin/ungoogled-chromium --ozone-platform=x11 --user-data-dir="$profile" --password-store=basic \
        --no-first-run --no-default-browser-check --disable-sync --noerrdialogs \
        --remote-debugging-address=127.0.0.1 --remote-debugging-port=${toString port} \
        --window-size=1920,1080 --user-agent=${lib.escapeShellArg userAgent}
    '';
  };
in {
  system.stateVersion = "24.05";

  microvm = {
    hypervisor = "qemu";
    mem = 4096;
    vcpu = 4;
    balloon = true;
    storeOnDisk = true;
    shares =
      map (p: {
        tag = "share-${builtins.substring 0 16 (builtins.hashString "sha1" p)}";
        source = p;
        mountPoint = p;
        proto = "9p";
      })
      ompBox.shares
      ++ [
        {
          tag = "shares";
          source = ompBox.sharesDir;
          mountPoint = "/mnt/shares";
          proto = "9p";
        }
      ]
      ++ [
        {
          tag = "auth";
          source = ompBox.authDir;
          mountPoint = "/etc/ssh/omp-box";
          proto = "9p";
          readOnly = true;
        }
        {
          tag = "natives";
          source = ompBox.nativesDir;
          mountPoint = "/mnt/omp-natives";
          proto = "9p";
          readOnly = true;
        }
        {
          tag = "seed";
          source = ompBox.seedDir;
          mountPoint = ompBox.seedMount;
          proto = "9p";
          readOnly = true;
        }
      ];
    interfaces = [];
    qemu.extraArgs = [
      "-netdev"
      "user,id=net0,hostfwd=tcp:127.0.0.1:${toString ompBox.port}-:22"
      "-device"
      "virtio-net-pci,netdev=net0"
    ];
  };

  environment.systemPackages = [ompBox.omp pkgs.bun pkgs.python3 pkgs.ungoogled-chromium pkgs.git pkgs.ripgrep pkgs.curl pkgs.gh pkgs.jq pkgs.fd pkgs.gnumake pkgs.gcc];
  fonts.packages = [pkgs.noto-fonts-cjk-sans];
  documentation.enable = false;

  boot.kernelParams = [
    "console=ttyS0"
    "loglevel=4"
    "sysctl.vm.mem_profiling=never"
    "kfence.sample_interval=0"
    "initcall_blacklist=ksm_init,tpm_init,init_tis"
    "psi=0"
    "transparent_hugepage=never"
  ];
  boot.blacklistedKernelModules = ["edac_core" "intel_rapl_msr" "intel_rapl_common" "kvm_amd" "kvm_intel" "kvm" "ccp" "irqbypass" "mousedev" "input_leds" "led_class" "cfg80211" "rfkill" "psmouse" "serio_raw" "atkbd" "i8042" "mac_hid" "pcspkr" "dm_mod" "loop" "virtiofs" "fuse"];

  networking = {
    hostName = "omp-box";
    firewall.enable = false;
    useNetworkd = true;
    nameservers = ["10.0.2.3"];
  };
  system.nssModules = lib.mkForce [];
  services = {
    resolved.enable = false;
    timesyncd.enable = false;
    nscd.enable = false;
    journald.settings.Journal = {
      Storage = "volatile";
      RuntimeMaxUse = "16M";
    };
    openssh = {
      enable = true;
      settings.PermitRootLogin = "no";
      settings.PasswordAuthentication = false;
      authorizedKeysFiles = ["/etc/ssh/omp-box/authorized_keys"];
    };
  };

  users.groups.users.gid = 100;
  users.users.${user} = {
    isNormalUser = true;
    uid = 1001;
    group = "users";
    extraGroups = ["wheel"];
  };
  security.sudo.wheelNeedsPassword = false;

  fileSystems = {
    "${home}/.omp/run" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["mode=0700" "uid=1001" "gid=100" "size=512M"];
    };
    "${home}/.omp/agent" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = ["mode=0700" "uid=1001" "gid=100" "size=2G"];
    };
  };

  systemd = {
    oomd.enable = false;
    network.networks."10-eth0" = {
      matchConfig.Driver = "virtio_net";
      networkConfig = {
        Address = ["10.0.2.15/24"];
        Gateway = "10.0.2.2";
        DNS = ["10.0.2.3"];
        Domains = ["home"];
      };
    };

    # Shares mount with sudo and would leave these root-owned, so the user's own programs couldn't write their caches and state beside them.
    tmpfiles.rules = map (dir: "d ${home}/${dir} 0755 ${user} users -") [".cache" ".config" ".local" ".local/share" ".local/state" ".local/state/omp-bot"];

    services =
      lib.mapAttrs' (name: settings: lib.nameValuePair "browser-${name}" (browser name settings)) ompBox.browsers
      // {
        "getty@tty1".enable = false;
        "autovt@".enable = false;
        "serial-getty@ttyS0".enable = false;
        omp-natives = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/mnt/omp-natives" "${home}/.omp/run"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            mkdir -p /run/omp-natives/upper /run/omp-natives/work ${home}/.omp/natives
            chown ${user}:users /run/omp-natives/upper
            ${pkgs.util-linux}/bin/mount -t overlay overlay \
              -o lowerdir=/mnt/omp-natives,upperdir=/run/omp-natives/upper,workdir=/run/omp-natives/work \
              ${home}/.omp/natives
          '';
        };
        # The omp config, read from the seed share's current generation at boot and again by the host's
        # omp-box-seed whenever it puts a new one there; at boot it waits for omp-box-seed's first copy.
        omp-seed = {
          wantedBy = ["multi-user.target"];
          unitConfig.RequiresMountsFor = ompBox.seedMount;
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "infinity";
          };
          script = ''
            set -eu
            src=${ompBox.seedMount}/current
            until [ -e "$src/config.yml" ]; do sleep 1; done
            dst=${home}/.omp/agent
            install -d -o 1001 -g 100 -m 755 ${home}/.omp
            install -d -o 1001 -g 100 -m 700 "$dst"
            for file in models.json settings.json config.yml models.yml APPEND_SYSTEM.md; do
              install -o 1001 -g 100 -m 600 "$src/$file" "$dst/$file"
            done
          '';
        };
      };
  };
}
