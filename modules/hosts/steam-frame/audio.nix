{pkgs, ...}: let
  receiverConfig = pkgs.writeText "60-frame-roc-source.conf" (builtins.toJSON {
    "context.modules" = [
      {
        name = "libpipewire-module-roc-source";
        flags = ["nofail"];
        args = {
          "local.ip" = "0.0.0.0";
          "local.source.port" = 10001;
          "local.repair.port" = 10002;
          "local.control.port" = 10003;
          "sess.latency.msec" = 40;
          "roc.resampler.profile" = "medium";
          "roc.latency-tuner.profile" = "responsive";
          "fec.code" = "rs8m";
          "source.name" = "frame-roc";
          "source.props" = {
            "node.name" = "frame-roc";
            "node.description" = "PC audio";
            "audio.rate" = 48000;
            "node.pause-on-idle" = false;
            "node.always-process" = true;
          };
          "audio.position" = "[ FL FR ]";
        };
      }
    ];
  });
in {
  services.pipewire.configPackages = [
    (pkgs.runCommand "frame-roc-source" {} ''
      install -Dm644 ${receiverConfig} $out/share/pipewire/pipewire.conf.d/60-frame-roc-source.conf
    '')
  ];

  networking.firewall = {
    allowedTCPPorts = [10003];
    allowedUDPPorts = [10001 10002 10003];
  };
}
