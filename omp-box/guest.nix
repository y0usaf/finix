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
  # The box user who works with the host user's own logins: no other Unix user can read the host's 0600
  # ~/.config/gh, ~/Tokens or CLI config, so the host copies what this bot needs into the auth share and
  # omp-logins installs it in this user's home, where gh, git's github.com helper and each CLI find it.
  loginUser = ompBox.logins;
  loginHome =
    let
      person = lib.findFirst (person: person.name == loginUser) null people;
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
  # Mounting runs in a helper of its own: a grant's target lives inside a home the bot owns, so every step has to
  # work on directory fds opened without following symlinks (see the comment at the top of share-mount.c).
  shareMount = pkgs.stdenv.mkDerivation {
    name = "omp-share-mount";
    dontUnpack = true;
    buildPhase = "${pkgs.stdenv.cc}/bin/cc -O2 -Wall -Wextra -o omp-share-mount ${./share-mount.c}";
    installPhase = "install -Dm755 omp-share-mount $out/bin/omp-share-mount";
  };
  # Applies the grants the host wrote for one user: the share tree is mounted once as root, and each grant is bind
  # mounted where that user's own paths live, inside its home and nowhere else. omp-shares runs this as root at
  # boot and whenever the host writes a new list, so no box user ever needs a way to mount anything.
  #
  # A bot reaches its grants through a view in which the host user's files are the bot's own. The box is another
  # Unix user, so a file the host writes belongs to neither the bot's uid nor its group, and no mode the host could
  # set short of open-to-everyone would let the bot write it; the view maps the host user's uid to the bot's with
  # bindfs, so every file there is the bot's to write whenever it was written and with whatever umask. The host's
  # files and their modes are never touched, and what the bot writes is still the host user's file, because the 9p
  # server writes as that user.
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

  environment.systemPackages = [
    ompBox.omp
    # The view omp-shares mounts over a bot's grants (see shareApply).
    pkgs.bindfs
    pkgs.bun
    pkgs.python3
    pkgs.ungoogled-chromium
    pkgs.git
    pkgs.ripgrep
    pkgs.curl
    pkgs.gh
    pkgs.jq
    pkgs.fd
    pkgs.gnumake
    pkgs.gcc
    # The work tools a bot ran on the host: node for the TypeScript repos, the postgres 16 client and server for
    # their tests, a JDK for gradle, the Google Workspace CLI, imagemagick for assets, and the two CLIs the host
    # itself wraps (agent-slack and vercel-account-router), built once in pkgs/ for the host and for this box.
    pkgs.nodejs
    pkgs.postgresql_16
    pkgs.jdk17
    pkgs.gws
    pkgs.imagemagick
    (import ../pkgs/agent-slack.nix {inherit pkgs;})
    # The box exists for the work account, so a bare `vercel` here answers as the host's vercel-work does: a folder
    # with no GitHub origin has nothing to route on, and refusing to guess would leave the bot with a dead command.
    (import ../pkgs/vercel-account-router.nix {
      inherit pkgs;
      default = "work";
    })
  ];
  # Commits made in the box are the host user's, as they were while the bots ran on the host (modules/tools/git.nix);
  # the host's own config is left out, since it sends github.com to ssh, which no box user has a key for.
  #
  # git reaches github.com as the account gh is logged in to: the helper asks gh, which reads the login in the box
  # user's own config, so no token is ever written into a URL, a remote or a file git reads. A user with no login
  # gets gh's own failure, and git falls back to asking for one.
  environment.etc."gitconfig".text = ''
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
  # initdb and the server it starts look for their data files beside the binary, which they find through the store
  # but not through the profile's bin: link postgres' share dir into the profile, so a bot starts a database from
  # PATH the way it did on the host from a nix build.
  environment.pathsToLink = ["/share/postgresql"];
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
  boot.blacklistedKernelModules = ["edac_core" "intel_rapl_msr" "intel_rapl_common" "kvm_amd" "kvm_intel" "kvm" "ccp" "irqbypass" "mousedev" "input_leds" "led_class" "cfg80211" "rfkill" "psmouse" "serio_raw" "atkbd" "i8042" "mac_hid" "pcspkr" "dm_mod" "loop" "virtiofs"];
  # A bot's view of its grants is a bindfs mount (omp-shares), so fuse is loaded at boot instead of on the first
  # mount, which would be the one omp-shares makes for a grant.
  boot.kernelModules = ["fuse"];

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
        DNS = ["1.1.1.1" "8.8.8.8"];
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
        # The host user's own logins, for the one bot that works with them: gh's login, the token files under
        # ~/Tokens, and the config each work CLI reads (agent-slack, vercel-work, gws, npm, supabase). The guest
        # cannot read the host's files (0600, another Unix user), so the host copied them into the auth share and
        # this installs them in the bot's own home. A re-login on the host reaches the box when it next boots.
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
                for file in models.json settings.json config.yml models.yml APPEND_SYSTEM.md; do
                  ${pkgs.util-linux}/bin/runuser -u ${person.name} -- ${pkgs.coreutils}/bin/install -m 600 "$src/$file" ${person.home}/.omp/agent/$file ||
                    echo "omp-seed: cannot install $file for ${person.name}" >&2
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
