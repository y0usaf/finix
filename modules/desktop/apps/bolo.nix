{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.programs.bolo;
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

  buildBoloPackages = provider:
    if provider == "cuda"
    then {
      bolod = flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}".bolod.override {
        sherpa-onnx = sherpaOnnxGpu;
      };
      inherit (flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}") bolo;
    }
    else flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}";

  boloPkgs = buildBoloPackages cfg.provider;
  autofillUdevRules = enabled:
    lib.optional enabled (pkgs.writeTextFile {
      name = "bolo-uinput-rules";
      destination = "/lib/udev/rules.d/99-bolo-uinput.rules";
      text = ''
        KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
      '';
    });
  autofillPipe = enabled: lib.mkIf enabled (lib.mkDefault "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | dotool");

  bolod = pkgs.symlinkJoin {
    name = "bolod-wrapped";
    paths = [boloPkgs.bolod];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/bolod --prefix PATH : ${lib.makeBinPath ([
          pkgs.pipewire
          pkgs.wl-clipboard
          pkgs.libnotify
          pkgs.coreutils
        ]
        ++ lib.optional cfg.autofill pkgs.dotool)}
    '';
  };
in {
  options.user.programs.bolo = {
    enable = lib.mkEnableOption "bolo speech-to-text daemon (bolod + thin client)";
    model = lib.mkOption {
      type = lib.types.enum (lib.attrNames models);
      default = "parakeet-v3-int8";
      description = "Active model; written to the bolod manifest.";
    };
    provider = lib.mkOption {
      type = lib.types.enum ["cpu" "cuda"];
      default = "cpu";
      description = ''
        onnxruntime execution provider. "cuda" rebuilds sherpa-onnx +
        onnxruntime with cudaSupport (long first build). cpu is the
        measured-sufficient default (12x real-time); cuda is opt-in.
      '';
    };
    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      description = "Dictation language hint recorded in the manifest.";
    };
    threads = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "Decoder threads; null = 50% of available cores (daemon default).";
    };
    pipeTo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional command the transcript is piped to after copy.";
    };
    vocabulary = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {};
      example = lib.literalExpression ''
        {
          Hyprland = ["hyper land"];
          niri = [];
        }
      '';
      description = ''
        Transcript corrections: canonical word -> known mishearings.
        bolod applies aliases exactly, then falls back to fuzzy matching
        (vocabFuzzy) for undeclared mishearings. Policy lives in the host,
        this module only compiles it into the manifest.
      '';
    };
    vocabFuzzy = lib.mkOption {
      type = lib.types.numbers.between 0.0 1.0;
      default = 0.85;
      description = ''
        Similarity threshold for bolod's fuzzy vocabulary pass; 0 disables
        it, leaving only exact alias/word matching.
      '';
    };
    autofill = lib.mkEnableOption "typing the transcript into the focused window (dotool/uinput)";
    tomoeKeybind = lib.mkOption {
      type = lib.types.str;
      default = "Mod+m";
      description = ''
        Tomoe push-to-talk bind (hold form): key-down spawns bolo to start
        recording, key-up spawns it again to stop and transcribe.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [boloPkgs.bolo];

    services.udev.packages = autofillUdevRules cfg.autofill;

    user.programs.bolo.pipeTo = autofillPipe cfg.autofill;

    manzil.users."${config.user.name}" = {
      files =
        {
          ".config/bolo/manifest.json".source = pkgs.writeText "bolo-manifest" (builtins.toJSON {
            version = 1;
            active = cfg.model;
            inherit (cfg) language provider threads;
            pipe_to = cfg.pipeTo;
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
            vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) cfg.vocabulary;
            vocab_fuzzy = cfg.vocabFuzzy;
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
      tomoe.process.service("bolod", {
        command = {"${bolod}/bin/bolod"},
        restart = "on_exit",
      })
      tomoe.bind("${cfg.tomoeKeybind}", {
        press = function() tomoe.spawn("${boloPkgs.bolo}/bin/bolo") end,
        release = function() tomoe.spawn("${boloPkgs.bolo}/bin/bolo") end,
      }, "Push-to-talk speech-to-text (bolo)")
    '';
  };
}
