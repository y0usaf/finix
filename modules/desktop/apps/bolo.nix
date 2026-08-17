{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.programs.bolo;
  # Parakeet TDT 0.6B v3 (int8), k2-fsa/csukuangfj sherpa-onnx export.
  # Declared once here; daemon manifest + manzil links derive from it
  # (doctrine 04/05). Add further models to this attrset — runtime model
  # installation does not exist in bolo by design.
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
  };

  modelDir = name: "${config.user.homeDirectory}/.local/share/bolo/models/${name}";

  # bolod build: provider picks the sherpa-onnx variant bolod links.
  # CUDA via k2-fsa's official prebuilt GPU release (cuda-12.x/cudnn-9.x,
  # same upstream version as nixpkgs sherpa-onnx). DOCTRINE-07 EXCEPTION:
  # binary blob — chosen because compiling onnxruntime[cudaSupport] is
  # hours of full-load build (and cudnn-frontend is broken on this cuda
  # pin). The compiled chain exists in git history (d2b3db8d) if a source
  # build is ever preferred. Runtime libs come from nixpkgs cudaPackages —
  # only sherpa-onnx/onnxruntime themselves are blobs.
  sherpaOnnxGpu = pkgs.stdenv.mkDerivation {
    pname = "sherpa-onnx-gpu-prebuilt";
    version = "1.13.3";
    src = pkgs.fetchurl {
      url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.3/sherpa-onnx-v1.13.3-cuda-12.x-cudnn-9.x-linux-x64-gpu.tar.bz2";
      hash = "sha256-6/Jllz8kHhwgOuMmLS5kK0zxHZd2OWjyvLM0FkBVIeg=";
    };
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = with pkgs.cudaPackages; [
      cuda_cudart
      libcublas
      libcurand
      libcufft
      cudnn
      pkgs.stdenv.cc.cc.lib
    ];
    installPhase = ''
      mkdir -p $out/include $out/lib
      cp -r include/sherpa-onnx $out/include/
      # Skip the tensorrt provider: unused (EP is "cuda") and would drag in
      # TensorRT for nothing.
      cp $(ls lib/*.so | grep -v tensorrt) $out/lib/
    '';
  };

  boloPkgs =
    if cfg.provider == "cuda"
    then {
      bolod = flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}".bolod.override {
        sherpa-onnx = sherpaOnnxGpu;
      };
      inherit (flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}") bolo;
    }
    else flakeInputs.bolo.packages."${pkgs.stdenv.hostPlatform.system}";

  # bolod is spawned by the compositor, whose PATH doesn't carry these.
  bolod = pkgs.symlinkJoin {
    name = "bolod-wrapped";
    paths = [boloPkgs.bolod];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/bolod --prefix PATH : ${lib.makeBinPath ([
          pkgs.pipewire # pw-record
          pkgs.wl-clipboard # wl-copy
          pkgs.libnotify # notify-send
          pkgs.coreutils # tr (autofill flatten) + sh plumbing
        ]
        # Autofill types via dotool/uinput; without it in the wrapper the
        # pipe_to command fails silently (pipe failures are swallowed by
        # design — clipboard is the backup).
        ++ lib.optionals cfg.autofill [pkgs.dotool])}
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
      default = "Mod+m"; # tomoe Mod = Alt
      description = ''
        Tomoe push-to-talk bind (hold form): key-down spawns bolo to start
        recording, key-up spawns it again to stop and transcribe.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [boloPkgs.bolo];

    # uinput node + input-group access for dotool autofill. Same rule asryx
    # installs; duplicate lines are harmless while both are enabled. Rules go
    # through services.udev.packages (portable: NixOS + finix), never
    # extraRules (NixOS-only — the finix compat shim drops it).
    services.udev.packages = lib.optionals cfg.autofill [
      (pkgs.writeTextFile {
        name = "bolo-uinput-rules";
        destination = "/lib/udev/rules.d/99-bolo-uinput.rules";
        text = ''
          KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
        '';
      })
    ];

    # Same autofill pipeline as asryx: flatten to one line, release all
    # modifiers on dotool's virtual keyboard first (tomoe merges xkb state).
    user.programs.bolo.pipeTo = lib.mkIf cfg.autofill (lib.mkDefault "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | dotool");

    manzil.users."${config.user.name}" = {
      files =
        {
          ".config/bolo/manifest.json".source = pkgs.writeText "bolo-manifest" (builtins.toJSON {
            version = 1;
            active = cfg.model;
            inherit (cfg) language provider threads;
            pipe_to = cfg.pipeTo;
            models =
              lib.mapAttrsToList (name: m: {
                inherit name;
                inherit (m) engine;
                encoder = "${modelDir name}/encoder.int8.onnx";
                decoder = "${modelDir name}/decoder.int8.onnx";
                joiner = "${modelDir name}/joiner.int8.onnx";
                tokens = "${modelDir name}/tokens.txt";
              })
              models;
            # One declaration mechanism: same attrset -> list shape as models.
            vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) cfg.vocabulary;
            vocab_fuzzy = cfg.vocabFuzzy;
          });
        }
        # Model files land where the manifest points.
        // lib.foldl' (acc: name:
          acc
          // lib.mapAttrs' (f: src:
            lib.nameValuePair ".local/share/bolo/models/${name}/${f}" {source = src;})
          models."${name}".files) {}
        (lib.attrNames models);
    };

    # Tomoe: supervised daemon + push-to-talk hold bind. process.service (not
    # spawn) so a bolod crash is respawned by tomoe's 1 Hz supervision tick
    # instead of leaving the keybind dead until the next login. restart
    # "on_exit" is the superset of "on_failure" (clean exits restart too) —
    # bolod is never supposed to exit on its own. reload keep_if_unchanged
    # (default) avoids paying model-load time on every config reload.
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
