{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  inherit ((import ../../hosts/shared.nix {inherit lib;}).bolo) model vocabulary;
  models.${model.name} = {
    inherit (model) engine;
    files =
      lib.mapAttrs (file: hash:
        pkgs.fetchurl {
          url = "${model.url}/${file}";
          inherit hash;
        })
      model.hashes;
  };

  modelDir = name: "${config.user.homeDirectory}/.local/share/bolo/models/${name}";

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

  streamingModel = pkgs.requireFile {
    name = "parakeet-unified-en-0.6b-streaming-320ms-fp32";
    hashMode = "recursive";
    hash = "sha256-WNF98/EvTK8+Q2rhZVr3cYAt1va8UdkLdxJAilv1LoQ=";
    message = ''
      The fp32 streaming export of nvidia/parakeet-unified-en-0.6b is not in
      the store. In a Python env with nemo_toolkit[asr], onnx, onnxruntime:

        curl -LO https://huggingface.co/nvidia/parakeet-unified-en-0.6b/resolve/main/parakeet-unified-en-0.6b.nemo
        curl -LO https://raw.githubusercontent.com/k2-fsa/sherpa-onnx/master/scripts/nemo/parakeet-unified-en-0.6b/export_onnx_streaming.py
        # The script has no 320ms preset; add it to LATENCY_PRESETS:
        #   "320ms": {"left": 70, "chunk": 1, "right": 3},
        python export_onnx_streaming.py --latency 320ms
        mkdir parakeet-unified-en-0.6b-streaming-320ms-fp32
        cp encoder.onnx encoder.weights decoder.onnx joiner.onnx tokens.txt parakeet-unified-en-0.6b-streaming-320ms-fp32/
        nix-store --add-fixed --recursive sha256 parakeet-unified-en-0.6b-streaming-320ms-fp32

      An export is not byte-reproducible; update the hash to the new path's.
    '';
  };

  keywords = pkgs.writeText "bolo-keywords.txt" "▁JA R VI S\n";

  manifestFile = pkgs.writeText "bolo-manifest" (builtins.toJSON {
    version = 1;
    active = "parakeet-unified";
    language = "en";
    provider = "cuda";
    threads = null;
    gain = 6.0;
    pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\n'; while IFS= read -r line || [ -n \"$line\" ]; do printf 'type %s\\n' \"$line\"; done; } | dotool";
    models =
      [
        {
          name = "parakeet-unified";
          engine = "sherpa-onnx-online-transducer";
          encoder = "${streamingModel}/encoder.onnx";
          decoder = "${streamingModel}/decoder.onnx";
          joiner = "${streamingModel}/joiner.onnx";
          tokens = "${streamingModel}/tokens.txt";
        }
        {
          name = "earlybird";
          engine = "earlybird";
          uri = lib.getExe inputPackages.bolo.earlybird;
          hold_words = 1;
          min_confidence = 0.9;
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
    vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) vocabulary;
    vocab_fuzzy = 0.85;
    wake = {
      kws = {
        model = "${kwsModel}";
        keywords = "${keywords}";
        threshold = 0.05;
      };
      vad = {
        model = "${vadModel}";
        threshold = 0.35;
        min_silence = 1.2;
      };
      max_turn = 60.0;
    };
  });

  userName = config.user.name;
  inherit (config.user) runtimeDir;

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

  inherit (inputPackages.bolo) bolo;

  bolod = pkgs.symlinkJoin {
    name = "bolod-wrapped";
    paths = [
      (inputPackages.bolo.bolod.override {
        sherpa-onnx = sherpaOnnxGpu;
      })
    ];
    nativeBuildInputs = [pkgs.makeWrapper];
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

    user.files =
      {
        ".config/bolo/manifest.json".source = manifestFile;
      }
      // lib.foldl' (acc: name:
        acc
        // lib.mapAttrs' (f: src:
          lib.nameValuePair ".local/share/bolo/models/${name}/${f}" {source = src;})
        models.${name}.files) {}
      (lib.attrNames (lib.filterAttrs (_: m: m ? files) models));

    finit.services.bolod = {
      description = "bolo speech-to-text daemon (${userName})";
      user = userName;
      reload-signal = "none";
      environment = {
        HOME = config.users.users.${userName}.home;
        XDG_RUNTIME_DIR = runtimeDir;
        BOLO_MANIFEST = "${manifestFile}";
        WAYLAND_DISPLAY = "tomoe-0";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=${runtimeDir}/tomoe.tomoe-0.bus";
      };
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
                                :press :description "Toggle speech-to-text (bolo)"))
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
                            (ui :row :padding '(5 10 5 10) :gap 4
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
