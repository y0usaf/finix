{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  hfBase = "https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main";
  models = {
    "parakeet-v3-int8" = {
      engine = "sherpa-onnx-transducer";
      files = {
        "encoder.int8.onnx" = pkgs.fetchurl {
          url = "${hfBase}/encoder.int8.onnx";
          hash = "sha256-rPwrRFY3fhXQTwJDr1QLf+fJkvjYmNdRzxNMOlX9Ikc=";
        };
        "decoder.int8.onnx" = pkgs.fetchurl {
          url = "${hfBase}/decoder.int8.onnx";
          hash = "sha256-F55QxD0aneeciiQUmi+brG61mBgj8qLtiNZVskJI204=";
        };
        "joiner.int8.onnx" = pkgs.fetchurl {
          url = "${hfBase}/joiner.int8.onnx";
          hash = "sha256-MWTBP8KCEAlEDSD8tf3Hi/8otNsvjQ8LMpEBcZwJSLM=";
        };
        "tokens.txt" = pkgs.fetchurl {
          url = "${hfBase}/tokens.txt";
          hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
        };
      };
    };
    "r2t2-streaming" = {
      engine = "r2t2-streaming";
      uri = "ws://${config.user.dev.r2t2.listenAddress}:${toString config.user.dev.r2t2.port}/asr_stream_api_v1";
      language = "English";
    };
  };

  modelDir = name: "${config.user.homeDirectory}/.local/share/bolo/models/${name}";

  sherpaOnnxGpu = pkgs.stdenv.mkDerivation {
    pname = "sherpa-onnx-gpu-prebuilt";
    version = "1.13.3";
    src = pkgs.fetchurl {
      url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.3/sherpa-onnx-v1.13.3-cuda-12.x-cudnn-9.x-linux-x64-gpu.tar.bz2";
      hash = "sha256-6/Jllz8kHhwgOuMmLS5kK0zxHZd2OWjyvLM0FkBVIeg=";
    };
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = [
      pkgs.cudaPackages.cuda_cudart
      pkgs.cudaPackages.libcublas
      pkgs.cudaPackages.libcurand
      pkgs.cudaPackages.libcufft
      pkgs.cudaPackages.cudnn
      pkgs.stdenv.cc.cc.lib
    ];
    installPhase = ''
      mkdir -p $out/include $out/lib
      cp -r include/sherpa-onnx $out/include/
      cp $(ls lib/*.so | grep -v tensorrt) $out/lib/
    '';
  };

  inherit (flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}") bolo;

  bolod = pkgs.symlinkJoin {
    name = "bolod-wrapped";
    paths = [
      (flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}".bolod.override {
        sherpa-onnx = sherpaOnnxGpu;
      })
    ];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/bolod --prefix PATH : ${lib.makeBinPath [
        pkgs.pipewire
        pkgs.wl-clipboard
        pkgs.libnotify
        pkgs.coreutils
        pkgs.dotool
      ]}
    '';
  };
in {
  options.user.programs.bolo.enable = lib.mkEnableOption "bolo speech-to-text daemon (bolod + thin client)" // {default = config.hardware.nvidia.enable;};

  config = lib.mkIf config.user.programs.bolo.enable {
    environment.systemPackages = [bolo];

    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "bolo-uinput-rules";
        destination = "/lib/udev/rules.d/99-bolo-uinput.rules";
        text = ''
          KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
        '';
      })
    ];

    manzil.users."${config.user.name}" = {
      files =
        {
          ".config/bolo/manifest.json".source = pkgs.writeText "bolo-manifest" (builtins.toJSON {
            version = 1;
            active = "parakeet-v3-int8";
            language = "en";
            provider = "cuda";
            threads = null;
            pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | dotool";
            models = lib.mapAttrsToList (name: m:
              {
                inherit name;
                inherit (m) engine;
              }
              // lib.optionalAttrs (m ? uri) {inherit (m) uri;}
              // lib.optionalAttrs (m ? language) {inherit (m) language;}
              // lib.optionalAttrs (m ? files) {
                encoder = "${modelDir name}/encoder.int8.onnx";
                decoder = "${modelDir name}/decoder.int8.onnx";
                joiner = "${modelDir name}/joiner.int8.onnx";
                tokens = "${modelDir name}/tokens.txt";
              })
            models;
            vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) {
              Hyprland = ["hyper land" "hipper land"];
              niri = ["neary" "nyree"];
              y0usaf = ["you sef" "yousef" "you saf"];
              "sherpa-onnx" = ["sherpa onyx" "sherpa onix"];
              tomoe = ["toe moe" "tomo eh"];
              ekko = ["eck oh" "eh ko"];
              moon = [];
              finix = ["fee nix" "finnix" "fi nix"];
            };
            vocab_fuzzy = 0.85;
          });
        }
        // lib.foldl' (acc: name:
          acc
          // lib.mapAttrs' (f: src:
            lib.nameValuePair ".local/share/bolo/models/${name}/${f}" {source = src;})
          models."${name}".files) {}
        (lib.attrNames (lib.filterAttrs (_: m: m ? files) models));
    };

    user.ui.tomoe.extraConfig = lib.mkIf config.user.ui.tomoe.enable ''
      (define-extension "bolo" (:reads (:key)) (snapshot state event)
        (declare (ignore snapshot))
        (values state
                (list (service :bolod (list "${bolod}/bin/bolod"))
                      (bind-key (list :alt) "m"
                                :press :release :release :description "Push-to-talk speech-to-text (bolo)"))
                (when (and (eq (getf event :type) :key) (equal (getf event :owner) "bolo"))
                  (list (launch "${bolo}/bin/bolo")))))
    '';
  };
}
