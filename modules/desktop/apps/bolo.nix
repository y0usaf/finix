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

  models =
    lib.mapAttrs (_: m:
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

  manifestFile = pkgs.writeText "bolo-manifest" (builtins.toJSON {
    version = 1;
    active = model.name;
    provider = "cuda";
    threads = null;
    # Whole-clip turns: one write of the finished transcript, typed once.
    pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | dotool";
    models =
      lib.mapAttrsToList (name: m:
        {
          inherit name;
          inherit (m) engine;
        }
        // lib.genAttrs ["encoder" "decoder" "joiner" "tokens"] (part: "${modelDir name}/${m.layout.${part}}"))
      models;
    vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) vocabulary;
    vocab_fuzzy = 0.85;
    turn = {
      vad = {
        open = 8.0;
        min_silence = 2.5;
      };
      start_timeout = 10.0;
      max_speech = null;
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
      (define-extension "bolo" (:reads (:command)) (snapshot state event)
        (declare (ignore snapshot))
        (values state
                (list (define-command "toggle-bolo"
                        :description "Start dictating, or stop (bolo).")
                      (define-command "release-bolo"
                        :description "Stop dictating if the key was held (bolo).")
                      (bind-key (list :alt) "m" "toggle-bolo" :release "release-bolo"
                                :description "Tap to dictate, or hold (bolo)."))
                (let ((name (and (eq (getf event :type) :command)
                                 (getf event :name))))
                  (when (member name '("toggle-bolo" "release-bolo") :test #'equal)
                    (list (launch "${bolo}/bin/bolo"
                                  (if (string= name "toggle-bolo") "toggle" "release")))))))
    '';
  };
}
