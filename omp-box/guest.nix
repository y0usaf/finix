{
  lib,
  pkgs,
  ompBox,
  ...
}: let
  inherit (ompBox) user bots;
  home = "/home/${user}";
  # Every Unix user the box has: the user's own sessions (the admin, which may reach any granted path the way it
  # always could) and one user per boxed bot. A bot's grants only ever land inside its own home, and the home is
  # 0700, so another bot or the user's sessions cannot even walk to them.
  people =
    [
      {
        name = user;
        uid = 1001;
        gid = 100;
        home = home;
        admin = true;
      }
    ]
    ++ map (bot: {
      name = bot.user;
      uid = bot.uid;
      gid = 100;
      home = "/home/${bot.user}";
      admin = false;
    })
    bots;
  botNames = map (bot: bot.user) bots;
  botsOf = name: lib.findFirst (bot: bot.name == name) null bots;
  browserUser = name: let
    found = botsOf name;
  in
    if found == null
    then user
    else found.user;
  # A host path as the same user sees it in the box: the bot users have a home of their own, so their state and
  # their folders keep their relative place under it.
  browserPath = name: path: let
    u = browserUser name;
    guestHome = if u == user then home else "/home/${u}";
  in
    if path == home
    then guestHome
    else if lib.hasPrefix "${home}/" path
    then guestHome + lib.removePrefix home path
    else path;
  userTable =
    lib.concatMapStringsSep "\n" (
      person: ''
        ${person.name}) uhome=${person.home} uuid=${toString person.uid} ugid=${toString person.gid} admin=${
          if person.admin
          then "1"
          else "0"
        } ;;''
    )
    people;
  # Applies the grants the host wrote for one user: the share tree is mounted once as root, and each grant is bind
  # mounted where that user's own paths live, inside its home and nowhere else. omp-shares runs this as root at
  # boot and whenever the host writes a new list, so no box user ever needs a way to mount anything.
  shareApply = pkgs.writeShellScript "omp-shares-apply" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.util-linux pkgs.gnugrep]}
    wanted=$1
    case "$wanted" in
    ${userTable}
    *) echo "omp-shares: $wanted is not a box user" >&2; exit 1 ;;
    esac
    manifest=/etc/omp-box/manifest
    run=/run/omp-box
    mkdir -p "$run"
    list="$run/$wanted.applied"
    : >"$list.new"
    status=0
    apply() {
      local name=$1 target=$2 flags=$3 parent p
      case "$target" in
        '~') target=$uhome ;;
        '~/'*) target="$uhome/''${target#'~/'}" ;;
        /*) ;;
        *) echo "omp-shares: $name has no target path, skipped" >&2; status=1; return ;;
      esac
      # A bot only ever sees paths below its own home; only the user's own sessions may reach further out.
      if [ "$admin" = 0 ]; then
        case "$target/" in
          "$uhome/"*) ;;
          *) echo "omp-shares: $name for $wanted points outside $uhome, refused" >&2; status=1; return ;;
        esac
      fi
      if [ ! -d "/run/omp-shares/$name" ]; then
        echo "omp-shares: $name is not in the box's share tree yet" >&2
        return
      fi
      parent=$(dirname -- "$target")
      mkdir -p -- "$parent" || {
        status=1
        return
      }
      # The folders between the home and the mount belong to the user, so it can write beside the mount.
      if [ "$admin" = 0 ]; then
        p=$parent
        while [ "$p" != "$uhome" ] && [ "$p" != / ]; do
          chown "$uuid:$ugid" -- "$p" 2>/dev/null || true
          p=$(dirname -- "$p")
        done
      fi
      [ -d "$target" ] || mkdir -p -- "$target" || return
      if ! mountpoint -q -- "$target"; then
        mount --bind "/run/omp-shares/$name" "$target" || {
          status=1
          return
        }
      fi
      case "$flags" in
        *ro*) mount -o remount,bind,ro -- "$target" || status=1 ;;
      esac
      printf '%s\n' "$target" >>"$list.new"
    }
    if [ -r "$manifest" ]; then
      while IFS=$'\t' read -r line_user name target flags; do
        [ -n "$line_user" ] || continue
        [ "$line_user" = "$wanted" ] || continue
        apply "$name" "$target" "$flags"
      done <"$manifest"
    fi
    # Grants the host revoked: unmount them, so a bot stops seeing a folder the moment the host takes it back.
    if [ -f "$list" ]; then
      while IFS= read -r old; do
        [ -n "$old" ] || continue
        grep -Fxq -- "$old" "$list.new" && continue
        umount -l -- "$old" 2>/dev/null || umount -- "$old" 2>/dev/null || true
      done <"$list"
    fi
    mv -f "$list.new" "$list"
    exit "$status"
  '';
  # pam_namespace reads its configuration out of the PAM store path it was built with, and a plain NixOS /etc
  # never reaches it, so the box builds the PAM it loads the module from and bakes the file in. Only the box's bot
  # users are polyinstantiated: a bot session gets a private /tmp and /var/tmp of its own, while the user's own
  # sessions keep the box's shared one.
  namespaceConf = ''
    /tmp      /tmp-inst/$USER      tmpfs:noinit:mntopts=size=256M,nosuid,nodev    ~${lib.concatStringsSep "," botNames}
    /var/tmp  /var/tmp-inst/$USER  tmpfs:noinit:mntopts=size=64M,nosuid,nodev     ~${lib.concatStringsSep "," botNames}
  '';
  pamNamespaces = pkgs.pam.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        printf '%s' ${lib.escapeShellArg namespaceConf} >$out/etc/security/namespace.conf
        chmod 0644 $out/etc/security/namespace.conf
      '';
  });
  # Headless Chromium says HeadlessChrome in its user agent, which shops turn away; claim the same version as Chrome.
  userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${lib.versions.major pkgs.ungoogled-chromium.version}.0.0.0 Safari/537.36";
  browser = name: {
    profile,
    port,
  }: let
    bot = botsOf name;
    runAs = browserUser name;
    asHome = browserPath name profile;
  in {
    description = "Chromium on a virtual screen for ${name}, DevTools on 127.0.0.1:${toString port}";
    wantedBy = ["multi-user.target"];
    startLimitIntervalSec = 0;
    environment.HOME = browserPath name home;
    serviceConfig = {
      User = runAs;
      Group = if bot == null then "users" else bot.user;
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      profile=${lib.escapeShellArg asHome}
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
    # The host store already holds this box's closure, so packing a second copy into a store disk image
    # only made the guest page-cache those pages in its own RAM: an idle box held ~560MB that way, and
    # ~120MB of it was the store. Reading the host's store over 9p instead costs ~2s of boot (9.6s
    # against 6.8s) and ~0.15s per uncached program start, and the same box idles at ~445MB.
    storeOnDisk = false;
    shares = [
      {
        tag = "store";
        source = "/nix/store";
        mountPoint = "/nix/store";
        proto = "9p";
        readOnly = true;
      }
    ] ++ map (p: {
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
          mountPoint = "/run/omp-shares";
          proto = "9p";
        }
        # What the host granted each user, one `user grant target ro|rw` line per grant, written by omp-box.
        {
          tag = "meta";
          source = ompBox.metaDir;
          mountPoint = "/etc/omp-box";
          proto = "9p";
          readOnly = true;
        }
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

  users.groups = {users = {gid = 100;};};
  users.users =
    {
      ${user} = {
        isNormalUser = true;
        uid = 1001;
        group = "users";
        extraGroups = ["wheel"];
      };
    }
    // lib.listToAttrs (map (bot: lib.nameValuePair bot.user {
        isNormalUser = true;
        uid = bot.uid;
        # The user's group, so a folder shared in from the host keeps the modes and ownership it has there.
        group = "users";
        home = "/home/${bot.user}";
        homeMode = "0700";
      })
      bots);
  # No bot is in wheel: the box mounts every shared folder as root when it boots (omp-shares), so nothing has to
  # hand a bot a way to mount or to become root.
  security.sudo.wheelNeedsPassword = false;

  fileSystems =
    {
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
    }
    // lib.listToAttrs (lib.concatMap (person: [
        (lib.nameValuePair "${person.home}/.omp/run" {
          device = "tmpfs";
          fsType = "tmpfs";
          options = ["mode=0700" "uid=${toString person.uid}" "gid=${toString person.gid}" "size=512M"];
        })
        (lib.nameValuePair "${person.home}/.omp/agent" {
          device = "tmpfs";
          fsType = "tmpfs";
          options = ["mode=0700" "uid=${toString person.uid}" "gid=${toString person.gid}" "size=2G"];
        })
      ])
      people);

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

    # The instance directories pam_namespace gives each bot session, and the empty parents it needs.
    tmpfiles.rules = [
      "d /tmp-inst 0000 root root -"
      "d /var/tmp-inst 0000 root root -"
      "d /run/omp-box 0755 root root -"
    ];

    services =
      lib.mapAttrs' (name: settings: lib.nameValuePair "browser-${name}" (browser name settings)) ompBox.browsers
      // {
        "getty@tty1".enable = false;
        "autovt@".enable = false;
        "serial-getty@ttyS0".enable = false;
        # One user's processes stay out of another's sight, which is what makes a bot unix user worth anything.
        omp-proc = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            ${pkgs.util-linux}/bin/mount -o remount,hidepid=2 /proc
          '';
        };
        # sshd only trusts a key file owned by root or by the user it lets in, and every file on a share reads as
        # the host user's, so each user gets the box key copied into its own home before sshd starts.
        omp-keys = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/etc/ssh/omp-box"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -eu
            ${lib.concatMapStringsSep "\n" (person: ''
              install -d -m 700 -o ${toString person.uid} -g ${toString person.gid} ${person.home}/.ssh
              install -m 600 -o ${toString person.uid} -g ${toString person.gid} /etc/ssh/omp-box/authorized_keys ${person.home}/.ssh/authorized_keys
            '')
            people}
          '';
        };
        # The shared tree is mounted as root at boot, and every grant the host wrote is bind mounted from here into
        # the one user's paths it names. Grants added while the box runs land within a couple of seconds.
        omp-shares = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/run/omp-shares" "/etc/omp-box"];
          serviceConfig.Restart = "always";
          script = ''
            set -u
            mkdir -p /run/omp-box
            # The share tree itself is root's: a bot reaches its own view through the folders omp-box granted it.
            chmod 0700 /run/omp-shares 2>/dev/null || true
            while :; do
              for person in ${lib.concatMapStringsSep " " (person: lib.escapeShellArg person.name) people}; do
                ${shareApply} "$person" || echo "omp-shares: a grant for $person did not apply" >&2
              done
              : >/run/omp-box/ready
              sleep 2
            done
          '';
        };
        omp-natives = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/mnt/omp-natives"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -eu
            mkdir -p /run/omp-natives
            ${lib.concatMapStringsSep "\n" (person: ''
              mkdir -p /run/omp-natives/upper-${person.name} /run/omp-natives/work-${person.name} ${person.home}/.omp/natives
              chown ${toString person.uid}:${toString person.gid} /run/omp-natives/upper-${person.name} ${person.home}/.omp/natives
              ${pkgs.util-linux}/bin/mount -t overlay overlay \
                -o lowerdir=/mnt/omp-natives,upperdir=/run/omp-natives/upper-${person.name},workdir=/run/omp-natives/work-${person.name} \
                ${person.home}/.omp/natives
            '')
            people}
          '';
        };
        # The omp config, read from the seed share's current generation at boot and again by the host's
        # omp-box-seed whenever it puts a new one there; at boot it waits for omp-box-seed's first copy.
        omp-seed = {
          wantedBy = ["multi-user.target"];
          unitConfig.RequiresMountsFor = [ompBox.seedMount] ++ map (person: "${person.home}/.omp/agent") people;
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "infinity";
          };
          script = ''
            set -eu
            src=${ompBox.seedMount}/current
            until [ -e "$src/config.yml" ]; do sleep 1; done
            for spec in ${lib.concatMapStringsSep " " (person: lib.escapeShellArg "${toString person.uid}:${toString person.gid}:${person.home}") people}; do
              IFS=: read -r uid gid dst <<<"$spec"
              install -d -m 755 "$dst/.omp"
              install -d -m 700 "$dst/.omp/agent"
              for file in models.json settings.json config.yml models.yml APPEND_SYSTEM.md; do
                install -m 600 "$src/$file" "$dst/.omp/agent/$file"
              done
              chown -R "$uid:$gid" "$dst/.omp/agent"
            done
          '';
        };
      };
  };

  security.pam.services.sshd.rules.session.namespace = {
    control = "required";
    order = 90000;
    modulePath = "${pamNamespaces}/lib/security/pam_namespace.so";
  };
}
