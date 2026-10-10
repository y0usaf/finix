{
  config,
  lib,
  pkgs,
  ...
}: let
  userName = config.user.name;
  runtimeDir = "/run/user/${toString config.users.users.${userName}.uid}";
  svcEnv = {
    HOME = config.users.users.${userName}.home;
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
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/state/wireplumber"
  ];
  finix.persistence.homeServices = ["wireplumber"];
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
      ''} ${pkgs.writeShellScript "pipewire-rt" ''
        export PATH=${lib.makeBinPath [pkgs.coreutils]}
        nice -n -20 "$@"
      ''} ${pkgs.pipewire}/bin/pipewire";
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
  };
}
