{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  user = config.users.users.${userName};
  inherit (user) home;
  runtimeDir = "/run/user/${toString user.uid}";
  svcEnv = {
    HOME = home;
    XDG_RUNTIME_DIR = runtimeDir;
    LADSPA_PATH = "${pkgs.rnnoise-plugin.ladspa}/lib/ladspa";
  };

  waitSock = pkgs.writeShellScript "wait-pipewire-sock" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    for _ in $(seq 1 60); do
      [ -S ${runtimeDir}/pipewire-0 ] && exec "$@"
      sleep 1
    done
    echo "wait-pipewire-sock: pipewire-0 never appeared" >&2
    exit 1
  '';

  pipewireRt = pkgs.writeShellScript "pipewire-rt" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    nice -n -20 "$@"
  '';
in {
  users.users.${userName}.extraGroups = ["audio"];

  environment.etc."pipewire/pipewire.conf.d/99-input-denoising.conf".text = builtins.toJSON {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Noise Cancelling source";
          "media.name" = "Noise Cancelling source";
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "librnnoise_ladspa";
                label = "noise_suppressor_mono";
                control = {
                  "VAD Threshold (%)" = 50;
                  "VAD Grace Period (ms)" = 20;
                  "Retroactive VAD Grace (ms)" = 0;
                };
              }
            ];
          };
          "audio.rate" = 48000;
          "audio.position" = ["MONO"];
          "capture.props" = {
            "node.name" = "capture.rnnoise_source";
            "node.passive" = true;
            "audio.rate" = 48000;
            "audio.channels" = 1;
          };
          "playback.props" = {
            "node.name" = "rnnoise_source";
            "media.class" = "Audio/Source";
            "audio.channels" = 1;
          };
        };
      }
    ];
  };

  environment.systemPackages = [
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.pulseaudio
  ];

  finit.services = {
    pipewire = {
      description = "pipewire (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${pkgs.writeShellScript "wait-runtime-dir" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils]}
        for _ in $(seq 1 60); do
          [ -d ${runtimeDir} ] && exec "$@"
          sleep 1
        done
        echo "wait-runtime-dir: ${runtimeDir} never appeared" >&2
        exit 1
      ''} ${pipewireRt} ${pkgs.pipewire}/bin/pipewire";
      log = true;
    };
    wireplumber = {
      description = "wireplumber session manager (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${waitSock} ${pkgs.wireplumber}/bin/wireplumber";
      log = true;
    };
    pipewire-pulse = {
      description = "pulseaudio compat (${userName})";
      user = userName;
      environment = svcEnv;
      command = "${waitSock} ${pkgs.pipewire}/bin/pipewire-pulse";
      log = true;
    };

    syncthing = {
      description = "syncthing file sync (${userName})";
      user = userName;
      environment.HOME = home;
      path = [pkgs.coreutils pkgs.gnugrep];
      command = let
        cfgDir = "${home}/.config/syncthing";
        seed = "${config.user.services.syncthing.seedConfigFile}";
      in "${pkgs.writeShellScript "syncthing-seed" ''
        set -e
        CFG=${cfgDir}/config.xml
        if [ ! -f "$CFG" ] || ! grep -q '<folder id=' "$CFG"; then
          install -m 600 -o ${userName} -g users ${seed} "$CFG"
        fi
        exec ${pkgs.syncthing}/bin/syncthing --config=${cfgDir} --data=${cfgDir} --gui-address=127.0.0.1:8384 --no-browser
      ''}";
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
