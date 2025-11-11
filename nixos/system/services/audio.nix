{pkgs, ...}: {
  config = {
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;

      # RNNoise neural network-based noise suppression for microphone
      extraConfig.pipewire."99-input-denoising" = {
        "context.modules" = [
          {
            "name" = "libpipewire-module-filter-chain";
            "args" = {
              "node.description" = "Noise Cancelling source";
              "media.name" = "Noise Cancelling source";
              "filter.graph" = {
                "nodes" = [
                  {
                    "type" = "ladspa";
                    "name" = "rnnoise";
                    "plugin" = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    "label" = "noise_suppressor_mono";
                    "control" = {
                      "VAD Threshold (%)" = 50; # Voice Activity Detection threshold
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
    };

    # RTKit - real-time audio priority
    security.rtkit.enable = true;
  };
}
