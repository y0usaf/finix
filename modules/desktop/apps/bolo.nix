{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  hfBase = "https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main";
  models =
    {
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
    }
    // lib.optionalAttrs config.user.dev.r2t2.enable {
      "r2t2-streaming" = {
        engine = "r2t2-streaming";
        uri = "ws://127.0.0.1:8272/asr_stream_api_v1";
        language = "English";
      };
    };

  modelDir = name: "${config.user.homeDirectory}/.local/share/bolo/models/${name}";

  # Wake word: a 3.3M streaming zipformer that spots keywords on CPU while the
  # recognizer stays idle, and silero for the endpoint decision.
  kwsModel =
    pkgs.runCommand "sherpa-onnx-kws-model" {
      src = pkgs.fetchurl {
        url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2";
        hash = "sha256-8XABO0cW5Btiub/YCWh8IHzveY75vGU01SThevm2Vho=";
      };
    } ''
      mkdir -p $out
      ${pkgs.bzip2}/bin/bunzip2 -c $src | ${pkgs.gnutar}/bin/tar -x --strip-components=1 -C $out
    '';

  vadModel = pkgs.fetchurl {
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx";
    hash = "sha256-niRJ4Qh0ltjUyrqQfyPgvT942R+lUkebucI6wJy7H9Y=";
  };

  # NVIDIA's parakeet-unified, exported by sherpa-onnx for streaming with
  # 1.12 s of lookahead: it decodes while you speak and only ever appends, at
  # 1.78 LibriSpeech-clean WER against 1.63 offline.
  streamingModel =
    pkgs.runCommand "parakeet-unified-en-0.6b-streaming-1120ms" {
      src = pkgs.fetchurl {
        url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-nemo-parakeet-unified-en-0.6b-int8-streaming-1120ms.tar.bz2";
        hash = "sha256-R4gimm3QO+M/gkPM7kjjOo0V33tEjLmRULDM3dGwLXQ=";
      };
    } ''
      mkdir -p $out
      ${pkgs.bzip2}/bin/bunzip2 -c $src | ${pkgs.gnutar}/bin/tar -x --strip-components=1 -C $out
    '';

  # The spotter's keyword file: BPE units, one keyword per line.
  keywords = pkgs.writeText "bolo-keywords.txt" "▁JA R VI S\n";

  # The daemon reads this store path directly, so a manifest change is a
  # service change and finit restarts bolod with it; reading the manzil copy
  # raced the restart and loaded the previous manifest.
  manifestFile = pkgs.writeText "bolo-manifest" (builtins.toJSON {
    version = 1;
    active = "parakeet-unified";
    language = "en";
    provider = "cuda";
    threads = null;
    # The Scarlett's input reaches bolo at around -28 dBFS peak; the
    # recognizer hears that as near-silence.
    gain = 6.0;
    # Each line is one increment and becomes one `type` command, so
    # dotool types it as it arrives; a single unterminated line would
    # be typed only when the turn ends.
    pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\n'; while IFS= read -r line || [ -n \"$line\" ]; do printf 'type %s\\n' \"$line\"; done; } | dotool";
    models =
      [
        {
          name = "parakeet-unified";
          engine = "sherpa-onnx-online-transducer";
          encoder = "${streamingModel}/encoder.int8.onnx";
          decoder = "${streamingModel}/decoder.int8.onnx";
          joiner = "${streamingModel}/joiner.int8.onnx";
          tokens = "${streamingModel}/tokens.txt";
        }
      ]
      ++ lib.mapAttrsToList (name: m:
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
    wake = {
      kws = {
        model = "${kwsModel}";
        keywords = "${keywords}";
        # Measured on five takes of the real word in this voice: 4/5
        # detected here, 1/5 at the 0.25 default, none at 0.5.
        threshold = 0.05;
      };
      vad = {
        model = "${vadModel}";
        # Quiet microphone: speech sits lower in the model's
        # probabilities, so demand less and pause more before a turn
        # ends. 0.6 s of silence cut sentences in half.
        threshold = 0.35;
        min_silence = 1.2;
      };
      # A guard against a VAD that never closes the turn; the streaming
      # engine has no clip length to stay under.
      max_turn = 60.0;
    };
  });

  userName = config.user.name;
  runtimeDir = "/run/user/${toString config.users.users.${userName}.uid}";

  sherpaOnnxGpu = pkgs.stdenv.mkDerivation {
    pname = "sherpa-onnx-gpu-prebuilt";
    version = "1.13.3";
    src = pkgs.fetchurl {
      url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v1.13.3/sherpa-onnx-v1.13.3-cuda-12.x-cudnn-9.x-linux-x64-gpu.tar.bz2";
      hash = "sha256-6/Jllz8kHhwgOuMmLS5kK0zxHZd2OWjyvLM0FkBVIeg=";
    };
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = [
      pkgs.cudaPackages_12.cuda_cudart
      pkgs.cudaPackages_12.libcublas
      pkgs.cudaPackages_12.libcurand
      pkgs.cudaPackages_12.libcufft
      pkgs.cudaPackages_12.cudnn
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
    # The daemon runs from finit with no inherited PATH: everything it spawns
    # by name — `sh` for pipe_to, dotool for typing — has to come from here.
    postBuild = ''
      wrapProgram $out/bin/bolod \
        --prefix PATH : ${lib.makeBinPath [pkgs.dotool pkgs.bash pkgs.coreutils]}
    '';
  };
in {
  config = lib.mkIf config.hardware.nvidia.enable {
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
          ".config/bolo/manifest.json".source = manifestFile;
        }
        // lib.foldl' (acc: name:
          acc
          // lib.mapAttrs' (f: src:
            lib.nameValuePair ".local/share/bolo/models/${name}/${f}" {source = src;})
          models."${name}".files) {}
        (lib.attrNames (lib.filterAttrs (_: m: m ? files) models));
    };

    finit.services.bolod = {
      description = "bolo speech-to-text daemon (${userName})";
      user = userName;
      environment = {
        HOME = config.users.users.${userName}.home;
        XDG_RUNTIME_DIR = runtimeDir;
        BOLO_MANIFEST = "${manifestFile}";
        WAYLAND_DISPLAY = "tomoe-0";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${runtimeDir}/tomoe.tomoe-0.bus";
      };
      # Boot runs before the session exists: wait for PipeWire, or the capture
      # process dies before it opens the microphone.
      command = "${pkgs.writeShellScript "bolod-start" ''
        i=0
        while [ "$i" -lt 600 ]; do
          [ -S ${runtimeDir}/pipewire-0 ] && exec ${bolod}/bin/bolod
          ${pkgs.coreutils}/bin/sleep 1
          i=$((i + 1))
        done
        echo "bolod-start: pipewire-0 never appeared" >&2
        exit 1
      ''}";
      log = true;
    };

    user.ui.tomoe.extraConfig = ''
      (define-extension "bolo" (:reads (:key)) (snapshot state event)
        (declare (ignore snapshot))
        (values state
                (list (bind-key (list :alt) "m"
                                :press :release :release :description "Push-to-talk speech-to-text (bolo)"))
                (when (and (eq (getf event :type) :key) (equal (getf event :owner) "bolo"))
                  (list (launch "${bolo}/bin/bolo")))))

      ;; The daemon writes its state file on every transition; this watches it
      ;; and shows a pill while a turn is in flight.
      ;; Centring has to be a margin: opposing anchors stretch a layer
      ;; surface, so the offset comes from the output's logical width.
      (defun bolo--margin (outputs width)
        (let* ((out (and (listp outputs) (car outputs)))
               (scale (if (and (listp out) (integerp (getf out :scale-120)))
                          (/ (getf out :scale-120) 120)
                          1))
               (logical (if (and (listp out) (integerp (getf out :width)))
                            (/ (getf out :width) scale)
                            width)))
          ;; Margin reads top, right, bottom, left.
          (list 44 0 0 (max 0 (round (- (/ logical 2) (/ width 2)))))))

      (define-extension "bolo-state" (:reads (:outputs) :state (list :state "idle"))
          (snapshot state event)
        (let ((current (getf state :state)))
          (when (eq (getf event :type) :watch)
            (setf current (or (getf event :content) "idle")))
          (when (string= current "") (setf current "idle"))
          (values (list :state current)
                  (append
                    (list (watch-file :state "${runtimeDir}/bolo/state"))
                    (unless (string= current "idle")
                      (list (shell-surface :bolo
                            (ui :row :padding '(5 10 5 10) :gap 4 :radius 6
                                :background "#1e1e2e"
                                :children
                                (list (ui :icon
                                          :name (cond ((string= current "listening") "audio-input-microphone")
                                                      ((string= current "transcribing") "process-working")
                                                      (t "media-record"))
                                          :size 18
                                          :color (if (string= current "recording") "#f38ba8" "#cdd6f4"))
                                      (ui :text :text current :size 12 :color "#cdd6f4")))
                              :width 148 :height 28 :anchors '(:top :left)
                              :margin (bolo--margin (context snapshot :outputs) 148)
                              :layer :overlay :exclusive-zone 0
                              :background "#00000000"))))
                  nil)))
    '';
  };
}
