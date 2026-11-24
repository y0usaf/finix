{
  lib,
  pkgs,
  ompBox,
  ...
}: let
  inherit (ompBox) user bots;
  home = "/home/${user}";
  people =
    [
      {
        name = user;
        uid = 1001;
        gid = 100;
        inherit home;
        admin = true;
      }
    ]
    ++ map (bot: {
      name = bot.user;
      inherit (bot) uid;
      gid = 100;
      home = "/home/${bot.user}";
      admin = false;
    })
    bots;
  botNames = map (bot: bot.user) bots;
  botsOf = name: lib.findFirst (bot: bot.name == name) null bots;
  sweepBot = botsOf "Sweep";
  loginUser = ompBox.logins;
  loginHome = let
    person = lib.findFirst (candidate: candidate.name == loginUser) null people;
  in
    if person == null
    then throw "ompBox.logins names ${loginUser}, which is not a user in the box"
    else person.home;
  browserUser = name: let
    found = botsOf name;
  in
    if found == null
    then user
    else found.user;
  browserPath = name: path: let
    u = browserUser name;
    guestHome =
      if u == user
      then home
      else "/home/${u}";
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
  shareMount = pkgs.stdenv.mkDerivation {
    name = "omp-share-mount";
    dontUnpack = true;
    buildPhase = "${pkgs.stdenv.cc}/bin/cc -O2 -Wall -Wextra -o omp-share-mount ${./share-mount.c}";
    installPhase = "install -Dm755 omp-share-mount $out/bin/omp-share-mount";
  };
  shareApply = pkgs.writeShellScript "omp-shares-apply" ''
    set -u
    export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gnugrep pkgs.util-linux pkgs.bindfs pkgs.fuse3]}
    wanted=$1
    case "$wanted" in
    ${userTable}
    *) echo "omp-shares: $wanted is not a box user" >&2; exit 1 ;;
    esac
    manifest=/etc/omp-box/manifest
    run=/run/omp-box
    # The host user's uid, which is what a grant's files belong to on the host; only the host knows it, so it writes
    # it beside the grants. Without it a grant still applies, unwrapped, and the bot cannot write what the host wrote.
    hostUid=
    if [ -r /etc/omp-box/host-uid ]; then read -r hostUid </etc/omp-box/host-uid; fi
    case "$hostUid" in ''' | *[!0-9]*) hostUid= ;; esac
    mkdir -p "$run"
    list="$run/$wanted.applied"
    views="$run/$wanted.views"
    : >"$list.new"
    : >"$views.new"
    status=0
    # view NAME - mount the bot's view of grant NAME and print where it landed. A view an earlier pass made is kept
    # as long as the daemon behind it still answers, so a pass that changes nothing mounts nothing; a view that no
    # longer answers is replaced, since a dead daemon leaves a mount that answers nothing.
    view() {
      local name=$1 place=/run/omp-mapped/$wanted/$1
      [ -n "$hostUid" ] || return 1
      case "$name" in ''' | */*) return 1 ;; esac
      # The views are allow_other, so what keeps one bot out of another's is this one root-only folder: a bot
      # reaches its own folder below it through the mount omp-share-mount binds into its home, never by walking
      # this path, and nothing but root can enter here at all.
      mkdir -p /run/omp-mapped || return 1
      chmod 0700 /run/omp-mapped || return 1
      mkdir -p "/run/omp-mapped/$wanted" || return 1
      if findmnt -n -o TARGET -- "$place" >/dev/null 2>&1; then
        if stat -c %i -- "$place" >/dev/null 2>&1; then
          printf '%s\n' "$name" >>"$views.new"
          printf '%s\n' "$place"
          return 0
        fi
        umount -l -- "$place" 2>/dev/null || true
      fi
      mkdir -p "$place" || return 1
      # bindfs says nothing when it works, and what it says when it does not belongs in the service's log rather
      # than in the path this function prints.
      if ! bindfs --map="$hostUid/$uuid:@$ugid/@$ugid" -o allow_other "/run/omp-shares/$name" "$place" >&2; then
        return 1
      fi
      printf '%s\n' "$name" >>"$views.new"
      printf '%s\n' "$place"
    }
    apply() {
      local name=$1 target=$2 flags=$3 how=rw home rel place want
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
      case "$flags" in
        *ro*) how=ro ;;
      esac
      if [ "$target" = "$uhome" ]; then
        home=$uhome rel=.
      elif [ "''${target#"$uhome"/}" != "$target" ]; then
        home=$uhome rel="''${target#"$uhome"/}"
      else
        home=/ rel=$target
      fi
      case "$home:$rel" in
        "/:.") want=/ ;;
        "/:/*") want=$rel ;;
        "/:"*) want="/$rel" ;;
        ":*") want=$uhome ;;
        *) want="$home/$rel" ;;
      esac
      # A bot's grant comes through its own view of the share (see view), and the user's own sessions bind the
      # share itself, so they see a granted folder exactly the way the host does.
      local source=/run/omp-shares/$name mapped
      if [ "$admin" = 0 ]; then
        if mapped=$(view "$name"); then
          source=$mapped
        else
          echo "omp-shares: $name reaches $wanted unwrapped, so $wanted cannot write what the host wrote" >&2
        fi
      fi
      # The helper resolves every component without following a symlink and mounts on the fd it opened, so a bot
      # that replaces a folder with a link gets a refusal instead of root acting wherever the link points.
      if place=$(${shareMount}/bin/omp-share-mount apply "$home" "$rel" "$uuid" "$ugid" "$how" "$source"); then
        printf '%s\n' "$place" >>"$list.new"
        return
      fi
      status=1
      # A pass that could not apply a grant keeps whatever is already mounted for it, so one refusal does not take
      # a working folder away from the bot the moment it is looked at.
      if grep -Fxq -- "$want" "$list" 2>/dev/null; then
        printf '%s\n' "$want" >>"$list.new"
      fi
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
        ${shareMount}/bin/omp-share-mount remove "$old" || true
      done <"$list"
    fi
    # A grant the host revoked takes its view with it: the daemon behind a view outlives the manifest line.
    if [ -d "/run/omp-mapped/$wanted" ]; then
      for place in "/run/omp-mapped/$wanted"/*; do
        [ -e "$place" ] || continue
        grep -Fxq -- "''${place##*/}" "$views.new" && continue
        umount -l -- "$place" 2>/dev/null || true
        rmdir -- "$place" 2>/dev/null || true
      done
    fi
    mv -f "$views.new" "$views"
    mv -f "$list.new" "$list"
    exit "$status"
  '';
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
  userAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/${lib.versions.major pkgs.ungoogled-chromium.version}.0.0.0 Safari/537.36";
  browser = name: {
    profile,
    port,
  }: let
    runAs = browserUser name;
    asHome = browserPath name profile;
  in {
    description = "Chromium on a virtual screen for ${name}, DevTools on 127.0.0.1:${toString port}";
    wantedBy = ["multi-user.target"];
    startLimitIntervalSec = 0;
    environment.HOME = browserPath name home;
    serviceConfig = {
      User = runAs;
      Group = "users";
      Restart = "always";
      RestartSec = 5;
    };
    script = ''
      profile=${lib.escapeShellArg asHome}
      case "$(${pkgs.util-linux}/bin/findmnt -n -o FSTYPE --target "$(dirname "$profile")")" in
        9p | fuse) ;;
        *)
          echo "$(dirname "$profile") is not shared into the box yet"
          exit 1
          ;;
      esac
      # What the browser writes is the host user's file on the host, so it writes with no umask of its own.
      umask 000
      mkdir -p "$profile"
      rm -f "$profile/SingletonLock" "$profile/SingletonCookie" "$profile/SingletonSocket"
      display=$((${toString port} - 9200))
      rm -f "/tmp/.X$display-lock" "/tmp/.X11-unix/X$display"
      ${pkgs.xvfb}/bin/Xvfb ":$display" -screen 0 1920x1080x24 -nolisten tcp &
      while [ ! -e "/tmp/.X11-unix/X$display" ]; do sleep 0.1; done
      export DISPLAY=":$display"
      # The box is the sandbox around this browser: chromium's own sandbox has no setuid helper here and its zygote
      # cannot hand off the renderer, so it runs without one, and the DevTools port is open to its own user alone.
      exec ${pkgs.ungoogled-chromium}/bin/chromium --ozone-platform=x11 --no-sandbox --no-zygote --user-data-dir="$profile" --password-store=basic \
        --no-first-run --no-default-browser-check --disable-sync --noerrdialogs \
        --remote-debugging-address=127.0.0.1 --remote-debugging-port=${toString port} \
        --window-size=1920,1080 --user-agent=${lib.escapeShellArg userAgent}
    '';
  };
in {
  system.stateVersion = "24.05";

  microvm = {
    hypervisor = "qemu";
    mem = 8192;
    vcpu = 4;
    balloon = true;
    storeOnDisk = false;
    shares =
      [
        {
          tag = "store";
          source = "/nix/store";
          mountPoint = "/nix/store";
          proto = "9p";
          readOnly = true;
        }
      ]
      ++ map (p: {
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

  environment = {
    systemPackages = [
      ompBox.omp
      pkgs.bindfs
      pkgs.bun
      (pkgs.python3.withPackages (ps: [ps.pillow ps.numpy ps.pandas ps.fonttools]))
      pkgs.ungoogled-chromium
      pkgs.git
      pkgs.ripgrep
      pkgs.curl
      pkgs.gh
      pkgs.jq
      pkgs.fd
      pkgs.gnumake
      pkgs.gcc
      pkgs.nodejs
      pkgs.postgresql_16
      pkgs.jdk17
      pkgs.gws
      pkgs.imagemagick
      (import ../pkgs/agent-slack.nix {inherit pkgs;})
      (import ../pkgs/vercel-account-router.nix {
        inherit pkgs;
        default = "work";
      })
    ];
    etc."gitconfig".text = ''
      [user]
      	name = ${user}
      	email = 74448287+y0usaf@users.noreply.github.com
      [init]
      	defaultBranch = main
      [pull]
      	rebase = true
      [push]
      	autoSetupRemote = true
      # The repos in the bot's workbench were cloned with git@github.com: remotes, which no box user has a key for, so
      # every GitHub ssh URL goes over https instead, through the same gh login.
      [url "https://github.com/"]
      	insteadOf = git@github.com:
      	insteadOf = ssh://git@github.com/
      [credential "https://github.com"]
      	helper = "!${pkgs.gh}/bin/gh auth git-credential"
      # A granted folder comes in from the host over 9p, so it belongs to the user the grant names rather than to the
      # bot that works in it, and git refuses every repository there as foreign without this.
      [safe]
      	directory = *
    '';
    pathsToLink = ["/share/postgresql"];
  };
  fonts.packages = [pkgs.noto-fonts-cjk-sans];
  documentation.enable = false;

  boot = {
    kernelParams = [
      "console=ttyS0"
      "loglevel=4"
      "sysctl.vm.mem_profiling=never"
      "kfence.sample_interval=0"
      "initcall_blacklist=ksm_init,tpm_init,init_tis"
      "psi=0"
      "transparent_hugepage=never"
    ];
    blacklistedKernelModules = ["edac_core" "intel_rapl_msr" "intel_rapl_common" "kvm_amd" "kvm_intel" "kvm" "ccp" "irqbypass" "mousedev" "input_leds" "led_class" "cfg80211" "rfkill" "psmouse" "serio_raw" "atkbd" "i8042" "mac_hid" "pcspkr" "dm_mod" "loop" "virtiofs"];
    kernelModules = ["fuse"];
  };

  networking = {
    hostName = "omp-box";
    firewall.enable = false;
    useNetworkd = true;
    nameservers = ["1.1.1.1" "8.8.8.8"];
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
    // lib.listToAttrs (map (bot:
        lib.nameValuePair bot.user {
          isNormalUser = true;
          inherit (bot) uid;
          group = "users";
          home = "/home/${bot.user}";
          homeMode = "0700";
        })
      bots);
  security.sudo.wheelNeedsPassword = false;

  fileSystems =
    {
      "/nix/store".options = ["cache=loose"];
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
        (lib.nameValuePair "${person.home}/.omp" {
          device = "tmpfs";
          fsType = "tmpfs";
          options = ["mode=0700" "uid=${toString person.uid}" "gid=${toString person.gid}" "size=512M"];
        })
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
        DNS = ["1.1.1.1" "8.8.8.8"];
        Domains = ["home"];
      };
    };

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
        omp-keys = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/etc/ssh/omp-box"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -u
            # A bot's home is the bot's to rewrite, so root must not walk a path under it: each write runs as the
            # user the file belongs to, and a link the bot plants there can only be followed with its own rights.
            ${lib.concatMapStringsSep "\n" (person: ''
                if ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -d -m 700 ${person.home}/.ssh &&
                   ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -m 600 /etc/ssh/omp-box/authorized_keys ${person.home}/.ssh/authorized_keys; then
                  :
                else
                  echo "omp-keys: cannot prepare ${person.home}/.ssh; ssh will refuse it" >&2
                fi
              '')
              people}
          '';
        };
        omp-logins = {
          wantedBy = ["multi-user.target"];
          unitConfig.RequiresMountsFor = ["/etc/ssh/omp-box"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -u -o pipefail
            # A bot's home is the bot's to rewrite, so root must not walk a path under it: every write below runs
            # with the bot's rights and reads a source only root can open, so a link the bot plants there can only
            # be followed with the bot's own.
            as_bot() {
              ${pkgs.util-linux}/bin/runuser -u ${loginUser} -- "$@"
            }
            src=/etc/ssh/omp-box/gh-hosts.yml
            if [ ! -r "$src" ]; then
              echo "omp-logins: $src is not in the auth share, so ${loginUser} has no GitHub login" >&2
            elif as_bot ${pkgs.coreutils}/bin/install -d -m 700 ${loginHome}/.config ${loginHome}/.config/gh &&
              as_bot ${pkgs.bash}/bin/sh -c "umask 077; cat > ${loginHome}/.config/gh/hosts.yml" <"$src"; then
              echo "omp-logins: installed $src as ${loginHome}/.config/gh/hosts.yml"
              # The host's gh prefers ssh, which no box user has a key for: gh's own git operations (gh repo
              # clone, gh pr checkout) use the https login just installed, through the helper in /etc/gitconfig.
              as_bot ${pkgs.gh}/bin/gh config set git_protocol https --host github.com ||
                echo "omp-logins: gh keeps the host's git protocol for ${loginUser}" >&2
            else
              echo "omp-logins: cannot install $src for ${loginUser}" >&2
            fi
            # The rest is one tree, laid out as it is in the host user's home: the token files under ~/Tokens and the
            # file or folder each CLI keeps its login in. It lands in the bot's home the same way, root reading the
            # share copy and the bot unpacking what it reads.
            src=/etc/ssh/omp-box/logins
            if [ ! -d "$src" ]; then
              echo "omp-logins: $src is not in the auth share, so ${loginUser} has no tokens" >&2
            elif ${pkgs.gnutar}/bin/tar -cf - -C "$src" . |
              as_bot ${pkgs.bash}/bin/sh -c 'umask 077; exec ${pkgs.gnutar}/bin/tar -xpf - -C "$1"' _ ${loginHome}; then
              echo "omp-logins: installed the host's tokens and CLI logins in ${loginHome}"
            else
              echo "omp-logins: cannot install $src for ${loginUser}" >&2
            fi
          '';
        };
        omp-shares = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/run/omp-shares" "/etc/omp-box"];
          serviceConfig.Restart = "always";
          script = ''
            set -u
            shopt -s nullglob
            mkdir -p /run/omp-box
            # The share tree itself is root's: a bot reaches its own view through the folders omp-box granted it.
            chmod 0700 /run/omp-shares 2>/dev/null || true
            last=
            checks=0
            while :; do
              uid=
              manifest=
              [ -r /etc/omp-box/host-uid ] && IFS= read -r -d "" uid </etc/omp-box/host-uid || true
              [ -r /etc/omp-box/manifest ] && IFS= read -r -d "" manifest </etc/omp-box/manifest || true
              now="$uid|$manifest"
              need=0
              [ "$now" = "$last" ] || need=1
              if [ "$need" = 0 ]; then
                checks=$((checks + 1))
                if [ "$checks" -ge 15 ]; then
                  checks=0
                  for view in /run/omp-mapped/*/*; do
                    ${pkgs.coreutils}/bin/stat -c %i -- "$view" >/dev/null 2>&1 || { need=1; break; }
                  done
                fi
              fi
              if [ "$need" = 1 ]; then
                ok=1
                for person in ${lib.concatMapStringsSep " " (person: lib.escapeShellArg person.name) people}; do
                  ${shareApply} "$person" || { ok=0; echo "omp-shares: a grant for $person did not apply" >&2; }
                done
                if [ "$ok" = 1 ]; then last=$now; else last=; fi
                checks=0
              fi
              : >/run/omp-box/ready
              sleep 2
            done
          '';
        };
        omp-natives = {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/mnt/omp-natives"] ++ map (person: "${person.home}/.omp") people;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -u
            mkdir -p /run/omp-natives
            ${lib.concatMapStringsSep "\n" (person: ''
                mkdir -p /run/omp-natives/upper-${person.name} /run/omp-natives/work-${person.name}
                # The mount point lives under a home the bot can rename, so the helper opens it a component at a
                # time without following a link and mounts on the fd; the upper and work folders are root's.
                if ! ${shareMount}/bin/omp-share-mount overlay ${person.home} .omp/natives /mnt/omp-natives \
                  /run/omp-natives/upper-${person.name} /run/omp-natives/work-${person.name}; then
                  echo "omp-natives: cannot mount ${person.home}/.omp/natives" >&2
                fi
              '')
              people}
          '';
        };
        omp-sweep = lib.mkIf (sweepBot != null) {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/etc/ssh/omp-box"];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -u
            bot=${sweepBot.user}
            home=${sweepBot.home or "/home/${sweepBot.user}"}
            src=/etc/ssh/omp-box/history/places.sqlite
            if [ -s "$src" ]; then
              # Root owns what it writes here, so the bot can read its history and cannot change it.
              if ${pkgs.coreutils}/bin/install -d -m 755 "$home/history" &&
                ${pkgs.coreutils}/bin/install -m 444 -o root -g root "$src" "$home/history/places.sqlite"; then
                echo "omp-sweep: put the browsing history at $home/history/places.sqlite"
              else
                echo "omp-sweep: cannot install $src for $bot" >&2
              fi
            else
              echo "omp-sweep: $src is missing or empty in the auth share, so $bot has no browsing history" >&2
            fi
          '';
        };
        omp-antigravity = lib.mkIf (bots != []) {
          wantedBy = ["multi-user.target"];
          before = ["sshd.service"];
          unitConfig.RequiresMountsFor = ["/etc/ssh/omp-box"] ++ lib.concatMap (bot: ["/home/${bot.user}/.omp/agent" "/home/${bot.user}/.omp/run"]) bots;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            set -u
            agy=/etc/ssh/omp-box/antigravity
            set -- "$agy"/*.json
            if [ ! -r "$1" ]; then
              echo "omp-antigravity: the auth share holds no Antigravity account, so the box answers on the fallback" >&2
              exit 0
            fi
            for bot in ${lib.concatMapStringsSep " " (bot: bot.user) bots}; do
              home=/home/$bot
              # The share copy is root's to read; the bot gets its own copy to import into its omp credential store.
              if inbox=$(${pkgs.util-linux}/bin/runuser -u "$bot" -- ${pkgs.coreutils}/bin/mktemp -d "$home/.omp/run/antigravity.XXXXXX"); then
                for file in "$agy"/*.json; do
                  ${pkgs.util-linux}/bin/runuser -u "$bot" -- ${pkgs.bash}/bin/bash -c "umask 077; cat > $(printf %q "$inbox/''${file##*/}")" <"$file" ||
                    echo "omp-antigravity: cannot copy $file for $bot" >&2
                done
                if ${pkgs.util-linux}/bin/runuser -u "$bot" -- ${pkgs.coreutils}/bin/env HOME="$home" ${ompBox.omp}/bin/omp auth-broker import "$inbox" --provider=antigravity-cli; then
                  echo "omp-antigravity: imported the Antigravity accounts for $bot"
                else
                  echo "omp-antigravity: cannot import the Antigravity accounts for $bot" >&2
                fi
                ${pkgs.util-linux}/bin/runuser -u "$bot" -- ${pkgs.coreutils}/bin/rm -rf "$inbox"
              else
                echo "omp-antigravity: cannot prepare an import folder for $bot" >&2
              fi
            done
          '';
        };
        omp-seed = {
          wantedBy = ["multi-user.target"];
          unitConfig.RequiresMountsFor = [ompBox.seedMount] ++ map (person: "${person.home}/.omp/agent") people;
          serviceConfig = {
            Type = "oneshot";
            TimeoutStartSec = "infinity";
          };
          script = ''
            set -u
            src=${ompBox.seedMount}/current
            until [ -e "$src/config.yml" ]; do sleep 1; done
            # Every write below is the bot's own: the seed is world-readable, and running install as the user
            # means a path the bot swapped for a link can only be followed with the bot's rights, never root's.
            ${lib.concatMapStringsSep "\n" (person: ''
                if [ ! -d ${person.home}/.omp ]; then
                  ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -d -m 755 ${person.home}/.omp ||
                    echo "omp-seed: cannot create ${person.home}/.omp" >&2
                fi
                if ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -d -m 700 ${person.home}/.omp/agent; then
                  for file in models.json settings.json config.yml models.yml AGENTS.md; do
                    ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -m 600 "$src/$file" ${person.home}/.omp/agent/$file ||
                      echo "omp-seed: cannot install $file for ${person.name}" >&2
                  done
                  ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/rm -f ${person.home}/.omp/agent/APPEND_SYSTEM.md ${person.home}/.omp/agent/SYSTEM_TEMPLATE.md
                  for pair in agents/task.md:task.md; do
                    dst=''${pair%%:*} srcfile=''${pair#*:}
                    ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -d -m 700 ${person.home}/.omp/agent/"''${dst%/*}" &&
                      ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -m 600 "$src/$srcfile" ${person.home}/.omp/agent/"$dst" ||
                      echo "omp-seed: cannot install $dst for ${person.name}" >&2
                  done
                else
                  echo "omp-seed: cannot prepare ${person.home}/.omp/agent" >&2
                fi
              '')
              people}
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
