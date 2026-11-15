{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  inherit ((import ../../hosts/shared.nix {inherit lib;}).bolo) model vocabulary;

  # One directory per model under ~/.local/share/bolo/models. The graphs load
  # their weights from a sibling `.data` file by name, so every file of a
  # model has to be installed side by side.
  modelDirs = {
    fluid-speech-pro = {
      engine = "sherpa-onnx-transducer";
      url = "https://huggingface.co/FluidVoice-Labs/fluid-speech-pro-onnx/resolve/main";
      layout = {
        encoder = "encoder-model.onnx";
        decoder = "decoder.onnx";
        joiner = "joiner.onnx";
        tokens = "vocab.txt";
      };
      hashes = {
        "encoder-model.onnx" = "sha256-YGMe+Msd8H7+bhmYtWrA+y/ahwWF/vz0lIrOa782G4k=";
        "encoder-model.onnx.data" = "sha256-w1C/NgZcOwdkKdHdRYyGlS1a7UnYz7ptqAOUS8YM9Y4=";
        "decoder.onnx" = "sha256-G6tePF+9ulCal55t8gkK4xCCn4vnLvpeJtxUEK2h5JQ=";
        "decoder.onnx.data" = "sha256-Yyw8v1nT5S0vf03aO/jijARfejuz2+8PRFKbpjkm76o=";
        "joiner.onnx" = "sha256-gE2WzIJcr4Kuu4DV4jX/wVva02qCIlASbia15xd9h8Y=";
        "joiner.onnx.data" = "sha256-QITbAjwESChwyoqqqkp7ktLOfJ9t3Y12LSH7VVInH+Q=";
        "vocab.txt" = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
      };
    };
    # NVIDIA Parakeet TDT v3, int8: the CPU alternative (see shared.nix).
    ${model.name} = {
      inherit (model) engine url hashes;
      layout = {
        encoder = "encoder.int8.onnx";
        decoder = "decoder.int8.onnx";
        joiner = "joiner.int8.onnx";
        tokens = "tokens.txt";
      };
    };
  };

  models = lib.mapAttrs (name: m:
    m
    // {
      files =
        lib.mapAttrs (file: hash:
          pkgs.fetchurl {
            url = "${m.url}/${file}";
            inherit hash;
          })
        m.hashes;
    })
  modelDirs;

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

  keywords = pkgs.writeText "bolo-keywords.txt" "▁JA R VI S\n";

  manifestFile = pkgs.writeText "bolo-manifest" (builtins.toJSON {
    version = 1;
    active = "fluid-speech-pro";
    provider = "cuda";
    threads = null;
    gain = 6.0;
    # Whole-clip turns: one write of the finished transcript, typed once.
    pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | dotool";
    models = lib.mapAttrsToList (name: m: {
      inherit name;
      inherit (m) engine;
      encoder = "${modelDir name}/${m.layout.encoder}";
      decoder = "${modelDir name}/${m.layout.decoder}";
      joiner = "${modelDir name}/${m.layout.joiner}";
      tokens = "${modelDir name}/${m.layout.tokens}";
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
      ;; Hold Alt+M to dictate. Key down starts the recorder; key up stops it,
      ;; and the finished clip is transcribed whole and typed once.
      (define-extension "bolo" (:reads (:command)) (snapshot state event)
        (declare (ignore snapshot))
        (values state
                (list (define-command "start-bolo"
                        :description "Start recording (bolo).")
                      (define-command "stop-bolo"
                        :description "Stop recording and transcribe (bolo).")
                      (bind-key (list :alt) "m" "start-bolo" :release "stop-bolo"
                                :description "Hold to dictate (bolo)."))
                (let ((name (and (eq (getf event :type) :command)
                                 (getf event :name))))
                  (when (member name '("start-bolo" "stop-bolo") :test #'equal)
                    (list (launch "${bolo}/bin/bolo"
                                  (if (string= name "start-bolo") "start" "stop")))))))

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
