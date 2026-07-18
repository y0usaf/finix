# Phase-2c: audio — pipewire + wireplumber + pulse compat as supervised
# finit services running as y0usaf (no systemd user sessions here; the
# server's syncthing service set the user+environment pattern).
# Port of modules/desktop/session/system/audio.nix (NixOS universe):
# same RNNoise mono source, same pulse/alsa compat surface. RT priority
# (Nice -20 / SCHED_RR 99 on NixOS) is NOT ported yet — needs rtkit or
# finit rlimit surgery; plain scheduling is fine for first sound.
{
  config,
  lib,
  pkgs,
  ...
}: let
  runtimeDir = "/run/user/1001";
  svcEnv = {
    HOME = "/home/y0usaf";
    XDG_RUNTIME_DIR = runtimeDir;
    # filter-chain resolves librnnoise_ladspa via LADSPA_PATH (NixOS module
    # does the same through extraLadspaPackages).
    LADSPA_PATH = "${pkgs.rnnoise-plugin.ladspa}/lib/ladspa";
  };

  # Same graph as the NixOS module's extraConfig."99-input-denoising";
  # real JSON is valid SPA-JSON.
  denoiseConf = builtins.toJSON {
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

  # Startup ordering without sockets-activation: wait, then become the
  # daemon. finit restarts us if the wait budget runs out.
  waitDir = pkgs.writeShellScript "wait-runtime-dir" ''
    export PATH=${lib.makeBinPath [pkgs.coreutils]}
    for _ in $(seq 1 60); do
      [ -d ${runtimeDir} ] && exec "$@"
      sleep 1
    done
    echo "wait-runtime-dir: ${runtimeDir} never appeared" >&2
    exit 1
  '';
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
  # /dev/snd is root:audio without logind ACLs.
  users.users.y0usaf.extraGroups = ["audio"];

  environment.etc."pipewire/pipewire.conf.d/99-input-denoising.conf".text = denoiseConf;

  environment.systemPackages = [
    pkgs.pipewire
    pkgs.wireplumber
    pkgs.pulseaudio # pactl against the pipewire-pulse socket
  ];

  finit.services = {
    pipewire = {
      description = "pipewire (y0usaf)";
      user = "y0usaf";
      environment = svcEnv;
      command = "${waitDir} ${pkgs.pipewire}/bin/pipewire";
      log = true;
    };
    wireplumber = {
      description = "wireplumber session manager (y0usaf)";
      user = "y0usaf";
      environment = svcEnv;
      command = "${waitSock} ${pkgs.wireplumber}/bin/wireplumber";
      log = true;
    };
    pipewire-pulse = {
      description = "pulseaudio compat (y0usaf)";
      user = "y0usaf";
      environment = svcEnv;
      command = "${waitSock} ${pkgs.pipewire}/bin/pipewire-pulse";
      log = true;
    };

    # Desktop syncthing, exact server pattern (same device identity dir on
    # persisted /home; GUI stays on localhost:8384, no proxy here).
    syncthing = {
      description = "syncthing file sync (y0usaf)";
      user = "y0usaf";
      environment.HOME = "/home/y0usaf";
      command = "${pkgs.syncthing}/bin/syncthing --config=/home/y0usaf/.config/syncthing --data=/home/y0usaf/.config/syncthing --gui-address=127.0.0.1:8384 --no-browser";
      conditions = ["net/lo/up"];
      log = true;
    };
  };
}
