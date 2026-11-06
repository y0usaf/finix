{
  config,
  lib,
  pkgs,
  flakeInputs,
  generators,
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

  stylesheet = name: nodes: pkgs.writeText name (generators.cssSource nodes);

  pluginPaths = {
    "plugins/cmus.path" = import ./config/plugins/cmus.data.nix;
    "plugins/ekko.path" = "${flakeInputs.tern-ekko}";
    "plugins/nix-fail.path" = import ./config/plugins/nix-fail.data.nix;
  };

  configFiles =
    {
      "carly/HEARTBEAT.md" = generators.sourceFile "HEARTBEAT.md" (generators.markdown.render (import ./config/carly/HEARTBEAT.data.nix generators.markdown));
      "carly/MEMORY.md" = generators.sourceFile "MEMORY.md" (generators.markdown.render (import ./config/carly/MEMORY.data.nix generators.markdown));
      "carly/SOUL.md" = generators.sourceFile "SOUL.md" (generators.markdown.render (import ./config/carly/SOUL.data.nix generators.markdown));
      "carly/USER.md" = generators.sourceFile "USER.md" (generators.markdown.render (import ./config/carly/USER.data.nix generators.markdown));
      "carly/memory/2026-10-29.md" = generators.sourceFile "2026-10-29.md" (generators.markdown.render (import ./config/carly/memory/2026-10-29.data.nix generators.markdown));
      "carly/memory/2026-10-30.md" = generators.sourceFile "2026-10-30.md" (generators.markdown.render (import ./config/carly/memory/2026-10-30.data.nix generators.markdown));
      "plugins/agent-tabs/plugin.toml" = generators.sourceFile "plugin.toml" (generators.tomlSource (import ./config/plugins/agent-tabs/plugin.data.nix));
      "plugins/agent-tabs/window.luau" = generators.sourceFile "window.luau" (import ./config/plugins/agent-tabs/window.data.nix);
      "plugins/block-menu/plugin.toml" = generators.sourceFile "plugin.toml" (generators.tomlSource (import ./config/plugins/block-menu/plugin.data.nix));
      "plugins/block-menu/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (import ./config/plugins/block-menu/window.data.nix generators.luau));
      "plugins/tab-order/plugin.toml" = generators.sourceFile "plugin.toml" (generators.tomlSource (import ./config/plugins/tab-order/plugin.data.nix));
      "plugins/tab-order/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (import ./config/plugins/tab-order/window.data.nix generators.luau));
      "plugins/tuturu/.gitignore" = generators.sourceFile ".gitignore" (generators.gitignoreSource (import ./config/plugins/tuturu/gitignore.data.nix));
      "plugins/tuturu/README.md" = generators.sourceFile "README.md" (generators.markdown.render (import ./config/plugins/tuturu/README.data.nix generators.markdown));
      "plugins/tuturu/plugin.toml" = generators.sourceFile "plugin.toml" (generators.tomlSource (import ./config/plugins/tuturu/plugin.data.nix));
      "plugins/tuturu/scripts/play.vbs" = generators.sourceFile "play.vbs" (generators.vbs.render (import ./config/plugins/tuturu/scripts/play.data.nix generators.vbs));
      "plugins/tuturu/sounds.toml" = generators.sourceFile "sounds.toml" (generators.tomlSource (import ./config/plugins/tuturu/sounds.data.nix));
      "plugins/tuturu/src/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (import ./config/plugins/tuturu/src/window.data.nix generators.luau));
      "plugins/ui-menu/plugin.toml" = generators.sourceFile "plugin.toml" (generators.tomlSource (import ./config/plugins/ui-menu/plugin.data.nix));
      "plugins/ui-menu/rail.luau" = generators.sourceFile "rail.luau" (generators.luau.render (import ./config/plugins/ui-menu/rail.data.nix generators.luau));
      "plugins/ui-menu/snippets/rail.css" = "${flakeInputs.tern-ozette}/rail.css";
      "plugins/ui-menu/snippets/settings.css" = "${flakeInputs.tern-ozette}/settings.css";
      "plugins/ui-menu/snippets/account.css" = stylesheet "account.css" (import ./config/plugins/ui-menu/snippets/account.data.nix);
      "plugins/ui-menu/snippets/answer-bubbles.css" = stylesheet "answer-bubbles.css" (import ./config/plugins/ui-menu/snippets/answer-bubbles.data.nix);
      "plugins/ui-menu/snippets/answer-frost.css" = stylesheet "answer-frost.css" (import ./config/plugins/ui-menu/snippets/answer-frost.data.nix);
      "plugins/ui-menu/snippets/attention.css" = stylesheet "attention.css" (import ./config/plugins/ui-menu/snippets/attention.data.nix);
      "plugins/ui-menu/snippets/bot-answer-bubbles.css" = stylesheet "bot-answer-bubbles.css" (import ./config/plugins/ui-menu/snippets/bot-answer-bubbles.data.nix);
      "plugins/ui-menu/snippets/bot-answer-frost.css" = stylesheet "bot-answer-frost.css" (import ./config/plugins/ui-menu/snippets/bot-answer-frost.data.nix);
      "plugins/ui-menu/snippets/bot-ask.css" = stylesheet "bot-ask.css" (import ./config/plugins/ui-menu/snippets/bot-ask.data.nix);
      "plugins/ui-menu/snippets/bot-cards.css" = stylesheet "bot-cards.css" (import ./config/plugins/ui-menu/snippets/bot-cards.data.nix);
      "plugins/ui-menu/snippets/bot-chao-motion.css" = stylesheet "bot-chao-motion.css" (import ./config/plugins/ui-menu/snippets/bot-chao-motion.data.nix);
      "plugins/ui-menu/snippets/bot-chao.css" = stylesheet "bot-chao.css" (import ./config/plugins/ui-menu/snippets/bot-chao.data.nix);
      "plugins/ui-menu/snippets/bot-chat-still.css" = stylesheet "bot-chat-still.css" (import ./config/plugins/ui-menu/snippets/bot-chat-still.data.nix);
      "plugins/ui-menu/snippets/bot-dock.css" = stylesheet "bot-dock.css" (import ./config/plugins/ui-menu/snippets/bot-dock.data.nix);
      "plugins/ui-menu/snippets/bot-events.css" = stylesheet "bot-events.css" (import ./config/plugins/ui-menu/snippets/bot-events.data.nix);
      "plugins/ui-menu/snippets/bot-jobs.css" = stylesheet "bot-jobs.css" (import ./config/plugins/ui-menu/snippets/bot-jobs.data.nix);
      "plugins/ui-menu/snippets/bot-layout.css" = stylesheet "bot-layout.css" (import ./config/plugins/ui-menu/snippets/bot-layout.data.nix);
      "plugins/ui-menu/snippets/bot-names.css" = stylesheet "bot-names.css" (import ./config/plugins/ui-menu/snippets/bot-names.data.nix);
      "plugins/ui-menu/snippets/bot-rail.css" = stylesheet "bot-rail.css" (import ./config/plugins/ui-menu/snippets/bot-rail.data.nix);
      "plugins/ui-menu/snippets/bot-spacing.css" = stylesheet "bot-spacing.css" (import ./config/plugins/ui-menu/snippets/bot-spacing.data.nix);
      "plugins/ui-menu/snippets/bot-stop.css" = stylesheet "bot-stop.css" (import ./config/plugins/ui-menu/snippets/bot-stop.data.nix);
      "plugins/ui-menu/snippets/bot-text.css" = stylesheet "bot-text.css" (import ./config/plugins/ui-menu/snippets/bot-text.data.nix);
      "plugins/ui-menu/snippets/bot-time.css" = stylesheet "bot-time.css" (import ./config/plugins/ui-menu/snippets/bot-time.data.nix);
      "plugins/ui-menu/snippets/bot-tints.css" = stylesheet "bot-tints.css" (import ./config/plugins/ui-menu/snippets/bot-tints.data.nix);
      "plugins/ui-menu/snippets/bot-turn-stats.css" = stylesheet "bot-turn-stats.css" (import ./config/plugins/ui-menu/snippets/bot-turn-stats.data.nix);
      "plugins/ui-menu/snippets/bot-work-rail.css" = stylesheet "bot-work-rail.css" (import ./config/plugins/ui-menu/snippets/bot-work-rail.data.nix);
      "plugins/ui-menu/snippets/bot-yorha-labels.css" = stylesheet "bot-yorha-labels.css" (import ./config/plugins/ui-menu/snippets/bot-yorha-labels.data.nix);
      "plugins/ui-menu/snippets/bot-you-frost.css" = stylesheet "bot-you-frost.css" (import ./config/plugins/ui-menu/snippets/bot-you-frost.data.nix);
      "plugins/ui-menu/snippets/bot-you.css" = stylesheet "bot-you.css" (import ./config/plugins/ui-menu/snippets/bot-you.data.nix);
      "plugins/ui-menu/snippets/bottom.css" = stylesheet "bottom.css" (import ./config/plugins/ui-menu/snippets/bottom.data.nix);
      "plugins/ui-menu/snippets/buttons.css" = stylesheet "buttons.css" (import ./config/plugins/ui-menu/snippets/buttons.data.nix);
      "plugins/ui-menu/snippets/centering.css" = stylesheet "centering.css" (import ./config/plugins/ui-menu/snippets/centering.data.nix);
      "plugins/ui-menu/snippets/chat-still.css" = stylesheet "chat-still.css" (import ./config/plugins/ui-menu/snippets/chat-still.data.nix);
      "plugins/ui-menu/snippets/dividers.css" = stylesheet "dividers.css" (import ./config/plugins/ui-menu/snippets/dividers.data.nix);
      "plugins/ui-menu/snippets/files.css" = stylesheet "files.css" (import ./config/plugins/ui-menu/snippets/files.data.nix);
      "plugins/ui-menu/snippets/frost.css" = stylesheet "frost.css" (import ./config/plugins/ui-menu/snippets/frost.data.nix);
      "plugins/ui-menu/snippets/grips.css" = stylesheet "grips.css" (import ./config/plugins/ui-menu/snippets/grips.data.nix);
      "plugins/ui-menu/snippets/inbox.css" = stylesheet "inbox.css" (import ./config/plugins/ui-menu/snippets/inbox.data.nix);
      "plugins/ui-menu/snippets/mini.css" = "${flakeInputs.tern-ozette}/mini.css";
      "plugins/ui-menu/snippets/ozette-answer-bubbles.css" = "${flakeInputs.tern-ozette}/ozette-answer-bubbles.css";
      "plugins/ui-menu/snippets/ozette-bot-you.css" = "${flakeInputs.tern-ozette}/ozette-bot-you.css";
      "plugins/ui-menu/snippets/ozette-cmus.css" = "${flakeInputs.tern-ozette}/cmus.css";
      "plugins/ui-menu/snippets/ozette-motion.css" = "${flakeInputs.tern-ozette}/motion.css";
      "plugins/ui-menu/snippets/ozette.css" = "${flakeInputs.tern-ozette}/ozette.css";
      "plugins/ui-menu/snippets/pane-borders.css" = stylesheet "pane-borders.css" (import ./config/plugins/ui-menu/snippets/pane-borders.data.nix);
      "plugins/ui-menu/snippets/rail_ages.css" = stylesheet "rail_ages.css" (import ./config/plugins/ui-menu/snippets/rail_ages.data.nix lib);
      "plugins/ui-menu/snippets/rail_card.css" = stylesheet "rail_card.css" (import ./config/plugins/ui-menu/snippets/rail_card.data.nix);
      "plugins/ui-menu/snippets/rail_compact.css" = stylesheet "rail_compact.css" (import ./config/plugins/ui-menu/snippets/rail_compact.data.nix);
      "plugins/ui-menu/snippets/rail_header.css" = stylesheet "rail_header.css" (import ./config/plugins/ui-menu/snippets/rail_header.data.nix);
      "plugins/ui-menu/snippets/rail_sections.css" = stylesheet "rail_sections.css" (import ./config/plugins/ui-menu/snippets/rail_sections.data.nix);
      "plugins/ui-menu/snippets/rail_status.css" = stylesheet "rail_status.css" (import ./config/plugins/ui-menu/snippets/rail_status.data.nix);
      "plugins/ui-menu/snippets/roomy.css" = stylesheet "roomy.css" (import ./config/plugins/ui-menu/snippets/roomy.data.nix);
      "plugins/ui-menu/snippets/row-keys.css" = stylesheet "row-keys.css" (import ./config/plugins/ui-menu/snippets/row-keys.data.nix);
      "plugins/ui-menu/snippets/scratch.css" = "${flakeInputs.tern-scratch}/min.css";
      "plugins/ui-menu/snippets/single.css" = stylesheet "single.css" (import ./config/plugins/ui-menu/snippets/single.data.nix);
      "plugins/ui-menu/snippets/tabs.css" = stylesheet "tabs.css" (import ./config/plugins/ui-menu/snippets/tabs.data.nix);
      "plugins/ui-menu/snippets/transparent.css" = stylesheet "transparent.css" (import ./config/plugins/ui-menu/snippets/transparent.data.nix);
      "plugins/ui-menu/snippets/turn-stats.css" = stylesheet "turn-stats.css" (import ./config/plugins/ui-menu/snippets/turn-stats.data.nix);
      "plugins/ui-menu/snippets/user-frost.css" = stylesheet "user-frost.css" (import ./config/plugins/ui-menu/snippets/user-frost.data.nix);
      "plugins/ui-menu/snippets/composer-frost.css" = stylesheet "composer-frost.css" (import ./config/plugins/ui-menu/snippets/composer-frost.data.nix);
      "plugins/ui-menu/snippets/width.css" = stylesheet "width.css" (import ./config/plugins/ui-menu/snippets/width.data.nix);
      "plugins/ui-menu/snippets/work-rail.css" = stylesheet "work-rail.css" (import ./config/plugins/ui-menu/snippets/work-rail.data.nix);
      "plugins/ui-menu/snippets/yorha-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/yorha-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/yorha-bot-you.css" = "${flakeInputs.tern-ozette}/yorha-bot-you.css";
      "plugins/ui-menu/snippets/yorha.css" = "${flakeInputs.tern-ozette}/yorha.css";
      "plugins/ui-menu/snippets/grok.css" = "${flakeInputs.tern-ozette}/grok.css";
      "plugins/ui-menu/snippets/grok-avatars.css" = "${flakeInputs.tern-ozette}/grok-avatars.css";
      "plugins/ui-menu/grok-bots/lloyd.png" = "${flakeInputs.tern-ozette}/grok-bots/lloyd.png";
      "plugins/ui-menu/grok-bots/sol.png" = "${flakeInputs.tern-ozette}/grok-bots/sol.png";
      "plugins/ui-menu/grok-bots/random.png" = "${flakeInputs.tern-ozette}/grok-bots/random.png";
      "plugins/ui-menu/grok-bots/cu.png" = "${flakeInputs.tern-ozette}/grok-bots/cu.png";
      "plugins/ui-menu/grok-bots/bao.png" = "${flakeInputs.tern-ozette}/grok-bots/bao.png";
      "plugins/ui-menu/grok-bots/regal.png" = "${flakeInputs.tern-ozette}/grok-bots/regal.png";
      "plugins/ui-menu/snippets/grok-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-user-bubbles.css" = "${flakeInputs.tern-ozette}/grok-user-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-answer-bubbles.css" = "${flakeInputs.tern-ozette}/grok-bot-answer-bubbles.css";
      "plugins/ui-menu/snippets/grok-bot-you.css" = "${flakeInputs.tern-ozette}/grok-bot-you.css";
      "plugins/ui-menu/window.luau" = generators.sourceFile "window.luau" (generators.luau.render (import ./config/plugins/ui-menu/window.data.nix generators.luau));
      "settings.json" = generators.sourceFile "settings.json" (generators.jsonSource (import ./config/settings.data.nix));
    }
    // lib.mapAttrs (name: path: generators.sourceFile (builtins.baseNameOf name) (generators.pathSource path)) pluginPaths;

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
