{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.user.programs.asryx;

  # Pinned to main d52de7f (2026-07-27); v1.3.0 predates GPU support and the
  # current ~/.local/share/asryx layout.
  asryxSrc = pkgs.fetchFromGitHub {
    owner = "rccyx";
    repo = "asryx";
    rev = "d52de7f77809e4323944343b98e74508add96244";
    hash = "sha256-kklQqvoLS7gW3WE8Tu8iQvtVYa2Z16mJshffukqfgV0=";
  };

  # asryx pins its inference backend; sha mirrors versions/whisper-cpp-sha in
  # the asryx source above. Keep both in lockstep when bumping.
  whisperSrc = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "whisper.cpp";
    rev = "fc674574ca27cac59a15e5b22a09b9d9ad62aafe";
    hash = "sha256-UFp62iUGrB57WZc3/N+L/8+NSeagan9ftAoTz6Yzqlk=";
  };

  # Models are provisioned declaratively from the store. Runtime
  # `asryx --model install` is unsupported here (needs a writable whisper.cpp
  # checkout in $HOME); add further models to this attrset instead.
  whisperModels = {
    "base.en" = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin";
      sha256 = "00nhqqvgwyl9zgyy7vk9i3n017q2wlncp5p7ymsk0cpkdp47jdx0";
    };
  };

  # Silero VAD; url + sha from asryx package/lib/_constants.sh.
  vadModel = pkgs.fetchurl {
    url = "https://huggingface.co/ggml-org/whisper-vad/resolve/9ffd54a1e1ee413ddf265af9913beaf518d1639b/ggml-silero-v6.2.0.bin";
    sha256 = "2aa269b785eeb53a82983a20501ddf7c1d9c48e33ab63a41391ac6c9f7fb6987";
  };

  runtimeDeps =
    [
      pkgs.pipewire # pw-record
      pkgs.wl-clipboard # wl-copy
      pkgs.libnotify # notify-send
    ]
    # Autofill types via uinput: daemonless dotool (no ydotoold service to
    # wire under finit) and compositor-agnostic (tomoe lacks the
    # zwp_virtual_keyboard_manager_v1 protocol that wtype needs).
    ++ lib.optionals cfg.autofill [pkgs.dotool];

  cudaBuild = cfg.backend == "cuda";
  vulkanBuild = cfg.backend == "vulkan";
  inherit (pkgs) cudaPackages;
  stdenv' =
    if cudaBuild
    then cudaPackages.backendStdenv
    else pkgs.stdenv;

  asryx = stdenv'.mkDerivation {
    pname = "asryx";
    version = "1.3.0-unstable-2026-07-27";
    src = asryxSrc;

    nativeBuildInputs =
      [pkgs.cmake pkgs.ninja pkgs.makeWrapper]
      ++ lib.optionals cudaBuild [
        cudaPackages.cuda_nvcc
        pkgs.autoAddDriverRunpath
      ]
      ++ lib.optionals vulkanBuild [pkgs.shaderc];

    buildInputs =
      lib.optionals cudaBuild [
        cudaPackages.cuda_cudart
        cudaPackages.libcublas
        cudaPackages.cuda_cccl
      ]
      ++ lib.optionals vulkanBuild [
        pkgs.vulkan-headers
        pkgs.vulkan-loader
        pkgs.spirv-headers
      ];

    cmakeFlags =
      ["-DBACKEND=${cfg.backend}"]
      ++ lib.optionals cudaBuild [
        "-DCMAKE_CUDA_ARCHITECTURES=${cfg.cudaArchitectures}"
      ];

    # CMakeLists resolves whisper.cpp via $HOME; stage the pinned checkout in
    # a fake build home instead of patching upstream.
    preConfigure = ''
      export HOME="$NIX_BUILD_TOP/fake-home"
      mkdir -p "$HOME/.local/share/asryx/deps"
      cp -r ${whisperSrc} "$HOME/.local/share/asryx/deps/whisper.cpp"
      chmod -R u+w "$HOME/.local/share/asryx/deps/whisper.cpp"
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 asryx $out/bin/asryx
      wrapProgram $out/bin/asryx \
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
      runHook postInstall
    '';

    meta = {
      description = "Native C++ ASR toggle for Linux (whisper.cpp in-process)";
      homepage = "https://github.com/rccyx/asryx";
      license = lib.licenses.mit;
      mainProgram = "asryx";
    };
  };
in {
  options.user.programs.asryx = {
    enable = lib.mkEnableOption "asryx speech-to-text toggle";
    backend = lib.mkOption {
      type = lib.types.enum ["cpu" "cuda" "vulkan"];
      default = "cpu";
      description = "Whisper inference backend.";
    };
    cudaArchitectures = lib.mkOption {
      type = lib.types.str;
      default = "89"; # RTX 4090
      description = "CMAKE_CUDA_ARCHITECTURES for the cuda backend.";
    };
    model = lib.mkOption {
      type = lib.types.enum (lib.attrNames whisperModels);
      default = "base.en";
      description = "Transcription model selected in ~/.asryx.conf.";
    };
    language = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = "Transcription language code or \"auto\".";
    };
    pipeTo = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Optional command the transcript is piped to after copy.";
    };
    autofill = lib.mkEnableOption "typing the transcript into the focused window (dotool/uinput)";
    keybind = lib.mkOption {
      type = lib.types.str;
      default = "Alt+M";
      description = "Niri bind that toggles record/transcribe.";
    };
    tomoeKeybind = lib.mkOption {
      type = lib.types.str;
      default = "Mod+m"; # tomoe Mod = Alt
      description = ''
        Tomoe push-to-talk bind (hold form): key-down spawns asryx to start
        recording, key-up spawns it again to stop and transcribe. The
        keycode-latched release fires even if the modifier is released first.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [asryx];

    # uinput node + input-group access for dotool; user is already in input
    # (modules/desktop/user-groups.nix).
    boot.kernelModules = lib.mkIf cfg.autofill ["uinput"];
    services.udev.extraRules = lib.mkIf cfg.autofill ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    # Flatten transcript to one line and type it into the focused window.
    # asryx always copies to the clipboard first, then pipes here.
    # The keyup prefix releases every modifier on dotool's virtual keyboard
    # first: tomoe merges all devices into one xkb state, so a physically
    # held Ctrl/Alt (e.g. the push-to-talk Mod released after the letter)
    # would otherwise fuse with the injected keys and fire shortcuts
    # instead of typing text. Cost: a still-held modifier goes inert until
    # physically re-pressed.
    user.programs.asryx.pipeTo = lib.mkIf cfg.autofill (lib.mkDefault (
      "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntype '; tr '\\n' ' '; } | dotool"
    ));

    manzil.users."${config.user.name}" = {
      files =
        {
          ".local/share/asryx/models/ggml-silero-v6.2.0.bin".source = vadModel;
          ".asryx.conf".source = pkgs.writeText "asryx-conf" ''
            model=${cfg.model}
            language=${cfg.language}
            pipe_to=${cfg.pipeTo}
          '';
        }
        // lib.mapAttrs' (name: src:
          lib.nameValuePair ".local/share/asryx/models/ggml-${name}.bin" {source = src;})
        whisperModels
        // lib.optionalAttrs config.user.ui.niri.enable {
          ".config/niri/config.kdl".value.binds."${cfg.keybind}" = {spawn = "asryx";};
        };
    };

    user.ui.tomoe.extraConfig = lib.mkIf config.user.ui.tomoe.enable ''
      tomoe.bind("${cfg.tomoeKeybind}", {
        press = function() tomoe.spawn("asryx") end,
        release = function() tomoe.spawn("asryx") end,
      }, "Push-to-talk speech-to-text")
    '';
  };
}
