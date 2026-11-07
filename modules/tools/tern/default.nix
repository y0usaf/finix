{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  version = "0.9.11";
  build = "20261104-025253-f93bb18";

  wpewebkit = import ../../../pkgs/wpewebkit.nix {inherit pkgs;};

  src = pkgs.requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    hashMode = "flat";
    hash = "sha256-rWHPGiz4l9/leuC/LmSp6MJSk2DBTc4lGFC+KOdg2+c=";
    message = ''
      Tern ${version} is a closed-beta build behind a Stencil account. Sign in
      at https://stencil.so/tern, download

        https://build.stencil.so/d/tern/${build}/Tern-${version}-linux-x86_64.tar.gz

      from the browser session that is signed in, then:

        nix-store --add-fixed sha256 Tern-${version}-linux-x86_64.tar.gz

      A new build needs both this URL's build id and the hash above.
    '';
  };

  tern = pkgs.stdenv.mkDerivation {
    pname = "tern";
    inherit version src;

    nativeBuildInputs = [pkgs.autoPatchelfHook pkgs.makeWrapper];
    buildInputs = [pkgs.stdenv.cc.cc.lib];
    runtimeDependencies = [
      pkgs.wayland
      pkgs.libxkbcommon
      pkgs.vulkan-loader
      pkgs.libglvnd
      pkgs.linux-pam
      pkgs.webkitgtk_4_1
      pkgs.libwpe-fdo
      wpewebkit
    ];

    installPhase = ''
      runHook preInstall
      install -Dm755 tern $out/bin/tern
      wrapProgram $out/bin/tern --prefix GIO_EXTRA_MODULES : ${pkgs.glib-networking}/lib/gio/modules --prefix PATH : ${lib.makeBinPath [pkgs.bubblewrap]}
      runHook postInstall
    '';

    meta = {
      description = "Tern, Stencil's GPU multiplexing terminal";
      homepage = "https://stencil.so/tern";
      mainProgram = "tern";
      platforms = ["x86_64-linux"];
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    };
  };

  registration = pkgs.runCommand "tern-registration" {} ''
    export HOME=$TMPDIR/home
    export XDG_DATA_HOME=$HOME/.local/share
    export XDG_CONFIG_HOME=$HOME/.config
    export XDG_CACHE_HOME=$HOME/.cache
    export XDG_STATE_HOME=$HOME/.local/state
    mkdir -p "$HOME"
    ${tern}/bin/tern register > /dev/null

    install -d $out/share
    cp -r "$XDG_DATA_HOME/applications" "$XDG_DATA_HOME/icons" $out/share/
    substituteInPlace $out/share/applications/*.desktop --replace-fail "/bin/.tern-wrapped" "/bin/tern"
    printf 'Path=%s\n' ${config.user.homeDirectory} >> $out/share/applications/so.stencil.tern.desktop
  '';

  package = pkgs.symlinkJoin {
    name = "tern-${version}";
    paths = [tern registration];
  };

  cmusTsp = pkgs.writeScriptBin "cmus-tsp" ''
    #!${pkgs.runtimeShell}
    exec ${pkgs.python3.withPackages (ps: [ps.numpy])}/bin/python3 ${config.user.homeDirectory}/dev/developing/tern-cmus/cmus-tsp "$@"
  '';

  ocean = "${pkgs.kdePackages.ocean-sound-theme}/share/sounds/ocean/stereo";

  tuturuClip = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/tuturu_1.mp3";
    hash = "sha256-cFN85xl8zdwaziqtnrzakuC+1pSAAU9AUbHz1HPrdEA=";
  };

  tuturuLevel = -34;

  tuturuSounds = pkgs.runCommand "tern-tuturu-sounds" {nativeBuildInputs = [pkgs.ffmpeg-headless pkgs.gawk];} ''
    mkdir $out
    level() {
      ffmpeg -nostats -loglevel error -i "$2" -af "''${3:-anull}" shaped.wav
      mean=$(ffmpeg -nostats -i shaped.wav -af volumedetect -f null - 2>&1 | awk '/mean_volume/ {print $(NF-1)}')
      ffmpeg -nostats -loglevel error -i shaped.wav -af "volume=$(awk -v m="$mean" 'BEGIN {print ${toString tuturuLevel} - m}')dB" -c:a libvorbis "$out/$1.ogg"
      rm shaped.wav
    }
    level alert ${ocean}/dialog-question.oga
    level yield ${tuturuClip} "aresample=48000,pan=mono|c0=0.5*c0+0.5*c1,highpass=f=80,equalizer=f=220:t=q:w=1:g=3,equalizer=f=650:t=q:w=1:g=-4,equalizer=f=3200:t=q:w=1:g=9,highshelf=f=6000:g=8,acompressor=threshold=-24dB:ratio=4:attack=3:release=60:makeup=2,alimiter=limit=0.9,asplit[near][far];[near]equalizer=f=150:t=q:w=1:g=4[right];[far]lowpass=f=2500,volume=-12dB,adelay=delays=22S:all=1[left];[right][left]join=inputs=2:channel_layout=stereo:map=0.0-FR|1.0-FL"
    level done ${ocean}/outcome-success.oga
  '';

  tuturu = {
    ".local/state/tern/plugin-data/tuturu/sounds.toml".text = ''
      alert = "${tuturuSounds}/alert.ogg"
      yield = "${tuturuSounds}/yield.ogg"
      done = "${tuturuSounds}/done.ogg"
      only_unfocused = true
      min_seconds = 30
    '';
  };

  pluginPaths = {
    "plugins/cmus.path" = lib.fileContents ./config/plugins/cmus.path;
    "plugins/ekko.path" = "${flakeInputs.tern-ekko}";
    "plugins/nix-fail.path" = lib.fileContents ./config/plugins/nix-fail.path;
  };

  configFiles =
    {
      "carly/HEARTBEAT.md" = ./config/carly/HEARTBEAT.md;
      "carly/MEMORY.md" = ./config/carly/MEMORY.md;
      "carly/SOUL.md" = ./config/carly/SOUL.md;
      "carly/USER.md" = ./config/carly/USER.md;
      "carly/memory/2026-10-29.md" = ./config/carly/memory/2026-10-29.md;
      "carly/memory/2026-10-30.md" = ./config/carly/memory/2026-10-30.md;
      "plugins/agent-tabs/plugin.toml" = ./config/plugins/agent-tabs/plugin.toml;
      "plugins/agent-tabs/window.luau" = ./config/plugins/agent-tabs/window.luau;
      "plugins/block-menu/plugin.toml" = ./config/plugins/block-menu/plugin.toml;
      "plugins/block-menu/window.luau" = ./config/plugins/block-menu/window.luau;
      "plugins/tab-order/plugin.toml" = ./config/plugins/tab-order/plugin.toml;
      "plugins/tab-order/window.luau" = ./config/plugins/tab-order/window.luau;
      "plugins/tuturu/.gitignore" = ./config/plugins/tuturu/.gitignore;
      "plugins/tuturu/README.md" = ./config/plugins/tuturu/README.md;
      "plugins/tuturu/plugin.toml" = ./config/plugins/tuturu/plugin.toml;
      "plugins/tuturu/scripts/play.vbs" = ./config/plugins/tuturu/scripts/play.vbs;
      "plugins/tuturu/sounds.toml" = ./config/plugins/tuturu/sounds.toml;
      "plugins/tuturu/src/window.luau" = ./config/plugins/tuturu/src/window.luau;
      "plugins/ui-menu/plugin.toml" = ./config/plugins/ui-menu/plugin.toml;
      "plugins/ui-menu/rail.luau" = ./config/plugins/ui-menu/rail.luau;
      "plugins/ui-menu/snippets/rail.css" = "${flakeInputs.tern-ozette}/rail.css";
      "plugins/ui-menu/snippets/settings.css" = "${flakeInputs.tern-ozette}/settings.css";
      "plugins/ui-menu/snippets/account.css" = ./config/plugins/ui-menu/snippets/account.css;
      "plugins/ui-menu/snippets/answer-bubbles.css" = ./config/plugins/ui-menu/snippets/answer-bubbles.css;
      "plugins/ui-menu/snippets/answer-frost.css" = ./config/plugins/ui-menu/snippets/answer-frost.css;
      "plugins/ui-menu/snippets/attention.css" = ./config/plugins/ui-menu/snippets/attention.css;
      "plugins/ui-menu/snippets/bot-answer-bubbles.css" = ./config/plugins/ui-menu/snippets/bot-answer-bubbles.css;
      "plugins/ui-menu/snippets/bot-answer-frost.css" = ./config/plugins/ui-menu/snippets/bot-answer-frost.css;
      "plugins/ui-menu/snippets/bot-ask.css" = ./config/plugins/ui-menu/snippets/bot-ask.css;
      "plugins/ui-menu/snippets/bot-cards.css" = ./config/plugins/ui-menu/snippets/bot-cards.css;
      "plugins/ui-menu/snippets/bot-chao-motion.css" = ./config/plugins/ui-menu/snippets/bot-chao-motion.css;
      "plugins/ui-menu/snippets/bot-chao.css" = ./config/plugins/ui-menu/snippets/bot-chao.css;
      "plugins/ui-menu/snippets/bot-chat-still.css" = ./config/plugins/ui-menu/snippets/bot-chat-still.css;
      "plugins/ui-menu/snippets/bot-dock.css" = ./config/plugins/ui-menu/snippets/bot-dock.css;
      "plugins/ui-menu/snippets/bot-events.css" = ./config/plugins/ui-menu/snippets/bot-events.css;
      "plugins/ui-menu/snippets/bot-jobs.css" = ./config/plugins/ui-menu/snippets/bot-jobs.css;
      "plugins/ui-menu/snippets/bot-layout.css" = ./config/plugins/ui-menu/snippets/bot-layout.css;
      "plugins/ui-menu/snippets/bot-names.css" = ./config/plugins/ui-menu/snippets/bot-names.css;
      "plugins/ui-menu/snippets/bot-rail.css" = ./config/plugins/ui-menu/snippets/bot-rail.css;
      "plugins/ui-menu/snippets/bot-spacing.css" = ./config/plugins/ui-menu/snippets/bot-spacing.css;
      "plugins/ui-menu/snippets/bot-stop.css" = ./config/plugins/ui-menu/snippets/bot-stop.css;
      "plugins/ui-menu/snippets/bot-text.css" = ./config/plugins/ui-menu/snippets/bot-text.css;
      "plugins/ui-menu/snippets/bot-time.css" = ./config/plugins/ui-menu/snippets/bot-time.css;
      "plugins/ui-menu/snippets/bot-tints.css" = ./config/plugins/ui-menu/snippets/bot-tints.css;
      "plugins/ui-menu/snippets/bot-turn-stats.css" = ./config/plugins/ui-menu/snippets/bot-turn-stats.css;
      "plugins/ui-menu/snippets/bot-work-rail.css" = ./config/plugins/ui-menu/snippets/bot-work-rail.css;
      "plugins/ui-menu/snippets/bot-yorha-labels.css" = ./config/plugins/ui-menu/snippets/bot-yorha-labels.css;
      "plugins/ui-menu/snippets/bot-you-frost.css" = ./config/plugins/ui-menu/snippets/bot-you-frost.css;
      "plugins/ui-menu/snippets/bot-you.css" = ./config/plugins/ui-menu/snippets/bot-you.css;
      "plugins/ui-menu/snippets/bottom.css" = ./config/plugins/ui-menu/snippets/bottom.css;
      "plugins/ui-menu/snippets/buttons.css" = ./config/plugins/ui-menu/snippets/buttons.css;
      "plugins/ui-menu/snippets/centering.css" = ./config/plugins/ui-menu/snippets/centering.css;
      "plugins/ui-menu/snippets/chat-still.css" = ./config/plugins/ui-menu/snippets/chat-still.css;
      "plugins/ui-menu/snippets/dividers.css" = ./config/plugins/ui-menu/snippets/dividers.css;
      "plugins/ui-menu/snippets/files.css" = ./config/plugins/ui-menu/snippets/files.css;
      "plugins/ui-menu/snippets/frost.css" = ./config/plugins/ui-menu/snippets/frost.css;
      "plugins/ui-menu/snippets/grips.css" = ./config/plugins/ui-menu/snippets/grips.css;
      "plugins/ui-menu/snippets/inbox.css" = ./config/plugins/ui-menu/snippets/inbox.css;
      "plugins/ui-menu/snippets/mini.css" = "${flakeInputs.tern-ozette}/mini.css";
      "plugins/ui-menu/snippets/ozette-answer-bubbles.css" = "${flakeInputs.tern-ozette}/ozette-answer-bubbles.css";
      "plugins/ui-menu/snippets/ozette-bot-you.css" = "${flakeInputs.tern-ozette}/ozette-bot-you.css";
      "plugins/ui-menu/snippets/ozette-cmus.css" = "${flakeInputs.tern-ozette}/cmus.css";
      "plugins/ui-menu/snippets/ozette-motion.css" = "${flakeInputs.tern-ozette}/motion.css";
      "plugins/ui-menu/snippets/ozette.css" = "${flakeInputs.tern-ozette}/ozette.css";
      "plugins/ui-menu/snippets/pane-borders.css" = ./config/plugins/ui-menu/snippets/pane-borders.css;
      "plugins/ui-menu/snippets/rail_ages.css" = ./config/plugins/ui-menu/snippets/rail_ages.css;
      "plugins/ui-menu/snippets/rail_card.css" = ./config/plugins/ui-menu/snippets/rail_card.css;
      "plugins/ui-menu/snippets/rail_compact.css" = ./config/plugins/ui-menu/snippets/rail_compact.css;
      "plugins/ui-menu/snippets/rail_header.css" = ./config/plugins/ui-menu/snippets/rail_header.css;
      "plugins/ui-menu/snippets/rail_sections.css" = ./config/plugins/ui-menu/snippets/rail_sections.css;
      "plugins/ui-menu/snippets/rail_status.css" = ./config/plugins/ui-menu/snippets/rail_status.css;
      "plugins/ui-menu/snippets/roomy.css" = ./config/plugins/ui-menu/snippets/roomy.css;
      "plugins/ui-menu/snippets/row-keys.css" = ./config/plugins/ui-menu/snippets/row-keys.css;
      "plugins/ui-menu/snippets/scratch.css" = "${flakeInputs.tern-scratch}/min.css";
      "plugins/ui-menu/snippets/single.css" = ./config/plugins/ui-menu/snippets/single.css;
      "plugins/ui-menu/snippets/tabs.css" = ./config/plugins/ui-menu/snippets/tabs.css;
      "plugins/ui-menu/snippets/transparent.css" = ./config/plugins/ui-menu/snippets/transparent.css;
      "plugins/ui-menu/snippets/turn-stats.css" = ./config/plugins/ui-menu/snippets/turn-stats.css;
      "plugins/ui-menu/snippets/user-frost.css" = ./config/plugins/ui-menu/snippets/user-frost.css;
      "plugins/ui-menu/snippets/composer-frost.css" = ./config/plugins/ui-menu/snippets/composer-frost.css;
      "plugins/ui-menu/snippets/width.css" = ./config/plugins/ui-menu/snippets/width.css;
      "plugins/ui-menu/snippets/work-rail.css" = ./config/plugins/ui-menu/snippets/work-rail.css;
      "plugins/ui-menu/snippets/yorha-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-you.css" = "${flakeInputs.tern-ozette}/yorha-bot-you.css";
      "plugins/ui-menu/snippets/yorha.css" = "${flakeInputs.tern-ozette}/yorha.css";
      "plugins/ui-menu/snippets/grok.css" = "${flakeInputs.tern-ozette}/grok.css";
      "plugins/ui-menu/snippets/grok-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-user-bubbles.css" = "${flakeInputs.tern-ozette}/grok-user-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-you.css" = "${flakeInputs.tern-ozette}/grok-bot-you.css";
      "plugins/ui-menu/window.luau" = ./config/plugins/ui-menu/window.luau;
      "settings.json" = ./config/settings.json;
    }
    // lib.mapAttrs (name: path: builtins.toFile (builtins.baseNameOf name) "${path}\n") pluginPaths;

  devTree = "${config.user.homeDirectory}/dev";

  devLinks = lib.filterAttrs (_: path: lib.hasPrefix "${devTree}/" path) pluginPaths;

  orphans =
    if lib.hasAttr devTree config.fileSystems
    then {}
    else devLinks;

  files =
    lib.mapAttrs' (name: file:
      lib.nameValuePair ".config/tern/${name}" {
        type = "copy";
        clobber = false;
        force = false;
        permissions = "0644";
        source = file;
      }) (removeAttrs configFiles (lib.attrNames orphans))
    // lib.mapAttrs' (name: _: lib.nameValuePair ".config/tern/${name}" {type = "delete";}) orphans;

  ternPeers = {
    y0usaf-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6ZHkn1pACV406TM5yUCRt/874vybgpUW3sUKka9nAC y0usaf@y0usaf-desktop";
    y0usaf-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjN9qndKm1iN0ctrucDNRBkfcZqC7zbRKR8SCD9E7KW y0usaf@y0usaf-server";
  };

  waitForMount = path: ''
    for _ in $(seq 1 20); do
      ${pkgs.util-linux}/bin/findmnt -n -o TARGET --mountpoint "${path}" >/dev/null 2>&1 && break
      sleep 0.5
    done
  '';

  remoteServe = pkgs.writeShellScript "tern-remote-serve" ''
    set -eu
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    ${waitForMount "${config.user.homeDirectory}/.config/tern"}
    ${waitForMount "${config.user.homeDirectory}/.local/state/tern"}
    exec ${package}/bin/tern remote serve --user --state-dir ${config.user.homeDirectory}/.config/tern
  '';

  seedAuthorizedKeys =
    pkgs.writeShellScript "tern-seed-authorized-keys" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gawk]}
      ${waitForMount "${config.user.homeDirectory}/.ssh"}
      dir="$HOME/.ssh"
      mkdir -p "$dir"
      chmod 0700 "$dir"
      auth="$dir/authorized_keys"
      touch "$auth"
      chmod 0600 "$auth"
      add() {
        kind="''${1%% *}"
        blob="$(printf '%s' "$1" | cut -d' ' -f2)"
        if awk -v k="$kind" -v b="$blob" '$1 == k && $2 == b { found = 1 } END { exit !found }' "$auth"; then
          return 0
        fi
        printf '%s\n' "$1" >> "$auth"
      }
      ${lib.concatMapStringsSep "
" (key: "add '${key}'") (lib.attrValues (lib.removeAttrs ternPeers [config.networking.hostName]))}
    '';
in {
  environment.variables.GIO_EXTRA_MODULES = lib.mkDefault "${pkgs.glib-networking}/lib/gio/modules";

  user.persist.directories = [
    ".config/tern"
    ".local/state/tern"
    ".local/state/brain"
    ".local/state/cmus-tsp"
    ".local/state/so.stencil.tern"
  ];

  user.files = files // tuturu;

  finit = {
    tmpfiles.rules = ["d ${config.user.runtimeDir} 0700 ${config.user.name} users"];

    tasks.tern-authorized-keys = {
      description = "seed ~/.ssh/authorized_keys for tern remote (${config.user.name})";
      user = config.user.name;
      environment.HOME = config.user.homeDirectory;
      command = seedAuthorizedKeys;
    };

    services.tern-remote = {
      description = "Tern remote sessions (${config.user.name})";
      user = config.user.name;
      environment = {
        HOME = config.user.homeDirectory;
        XDG_RUNTIME_DIR = config.user.runtimeDir;
      };
      command = remoteServe;
      conditions = ["net/lo/up" "task/tmpfiles-setup/success"];
      log = true;
    };
  };

  environment.systemPackages = [package cmusTsp];
}
