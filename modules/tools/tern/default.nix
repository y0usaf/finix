{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  version = "0.9.7";
  build = "20261028-175324-c2f7563";

  wpewebkit = import ../../../pkgs/wpewebkit.nix {inherit pkgs;};

  src = pkgs.requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    hashMode = "flat";
    hash = "sha256-DPKeJdibqTNIy/YsryEX6AbCSR+RNAt+sfxo2AqE5jg=";
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

  tuturu = pkgs.fetchurl {
    url = "https://www.myinstants.com/media/sounds/tuturu_1.mp3";
    hash = "sha256-cFN85xl8zdwaziqtnrzakuC+1pSAAU9AUbHz1HPrdEA=";
  };

  chimeLevel = -34;

  chimeSounds = pkgs.runCommand "tern-chime-sounds" {nativeBuildInputs = [pkgs.ffmpeg-headless pkgs.gawk];} ''
    mkdir $out
    level() {
      ffmpeg -nostats -loglevel error -i "$2" -af "''${3:-anull}" shaped.wav
      mean=$(ffmpeg -nostats -i shaped.wav -af volumedetect -f null - 2>&1 | awk '/mean_volume/ {print $(NF-1)}')
      ffmpeg -nostats -loglevel error -i shaped.wav -af "volume=$(awk -v m="$mean" 'BEGIN {print ${toString chimeLevel} - m}')dB" -c:a libvorbis "$out/$1.ogg"
      rm shaped.wav
    }
    level alert ${ocean}/dialog-question.oga
    level yield ${tuturu} "pan=mono|c0=0.5*c0+0.5*c1,highpass=f=80,equalizer=f=220:t=q:w=1:g=3,equalizer=f=650:t=q:w=1:g=-4,equalizer=f=3200:t=q:w=1:g=9,highshelf=f=6000:g=8,acompressor=threshold=-24dB:ratio=4:attack=3:release=60:makeup=2,alimiter=limit=0.9"
    level done ${ocean}/outcome-success.oga
  '';

  chime = {
    ".config/tern/plugins/chime.path".text = "${flakeInputs.tern-chime}\n";
    ".local/state/tern/plugin-data/chime/sounds.toml".text = ''
      alert = "${chimeSounds}/alert.ogg"
      yield = "${chimeSounds}/yield.ogg"
      done = "${chimeSounds}/done.ogg"
      only_unfocused = true
      min_seconds = 30
    '';
  };

  configDir = ./config;

  devTree = "${config.user.homeDirectory}/dev";

  configFiles = lib.filesystem.listFilesRecursive configDir;

  relative = file: lib.removePrefix "${toString configDir}/" (toString file);

  pointsIntoDevTree = file: lib.hasPrefix "${devTree}/" (lib.fileContents (toString file));

  devLinks = builtins.filter (file: lib.hasSuffix ".path" (toString file) && pointsIntoDevTree file) configFiles;

  orphans =
    if lib.hasAttr devTree config.fileSystems
    then []
    else devLinks;

  files =
    lib.listToAttrs (map (file: {
      name = ".config/tern/${relative file}";
      value = {
        type = "copy";
        clobber = false;
        force = false;
        permissions = "0644";
        source = file;
      };
    }) (lib.subtractLists orphans configFiles))
    // lib.genAttrs (map (file: ".config/tern/${relative file}") orphans) (_: {type = "delete";});

  # `tern remote serve --user` admits any key in the target user's own
  # ~/.ssh/authorized_keys. That is a different file from sshd's
  # AuthorizedKeysFile here (/etc/ssh/authorized_keys.d/%u, forced in
  # ./finix/common.nix), so a working `ssh server` says nothing about Tern:
  # each host needs the other's key in that file. Only public halves live here.
  ternPeers = {
    y0usaf-desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6ZHkn1pACV406TM5yUCRt/874vybgpUW3sUKka9nAC y0usaf@y0usaf-desktop";
    y0usaf-server = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjN9qndKm1iN0ctrucDNRBkfcZqC7zbRKR8SCD9E7KW y0usaf@y0usaf-server";
  };

  # Append, never rewrite: the phone pairing adds its own key to this file, and
  # it must stay a real writable file rather than a store symlink.
  seedAuthorizedKeys =
    pkgs.writeShellScript "tern-seed-authorized-keys" ''
      set -eu
      export PATH=${lib.makeBinPath [pkgs.coreutils pkgs.gawk]}
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

  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".config/tern"
    ".local/state/tern"
  ];

  manzil.users.${config.user.name}.files = files // chime;

  finit = {
    tmpfiles.rules = [
      "d /run/user/${toString config.users.users.${config.user.name}.uid} 0700 ${config.user.name} users"
    ];

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
        XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.${config.user.name}.uid}";
      };
      command = "${package}/bin/tern remote serve --user --state-dir ${config.user.homeDirectory}/.config/tern";
      conditions = ["net/lo/up" "task/tmpfiles-setup/success"];
      log = true;
    };
  };

  environment.systemPackages = [package cmusTsp];
}
