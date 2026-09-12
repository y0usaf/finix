{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.programs.baat;

  # Sibling of bolo: a duplex voice bot whose daemon owns the audio loop and
  # whose trigger state (push-to-talk arm/close) lives in the daemon
  # ([[principle:daemon-thin-client]]). The compositor side is therefore only a
  # keybind table entry plus a supervised command — no code
  # ([[principle:least-power]]: config, not a program).
  baatPkgs = flakeInputs.baat.packages."${pkgs.stdenv.hostPlatform.system}";

  # Models already on disk under ~/.paseo/models/local-speech (persisted by
  # hosts/y0usaf-desktop/impermanence.nix). Pointing the manifest at them avoids
  # re-declaring ~1 GB of fetchurl downloads for files that are present;
  # declaring them the bolo.nix way (store paths + hashes) is possible later if
  # they should become reproducible. STT is parakeet TDT 0.6B v2 int8, TTS is
  # kokoro-en-v0_19, VAD is silero.
  stt = "${cfg.modelsDir}/sherpa-onnx-nemo-parakeet-tdt-0.6b-v2-int8";
  tts = "${cfg.modelsDir}/kokoro-en-v0_19";
  vad = "${cfg.modelsDir}/silero-vad";

  # Generated, never hand-edited ([[principle:unix]] row 7). Every key baat's
  # config.load requires is present; an unknown key is fatal to the daemon.
  # duplex.trigger ships "ptt": the mic is idle until the press, the press is
  # the interrupt, and silence never closes a turn — so the keybind is
  # press-only (see the bind below).
  manifest = {
    version = 1;
    inherit (cfg) provider;
    llm = {
      base_url = cfg.llm.baseUrl;
      inherit (cfg.llm) model;
      api_key_env = "";
      temperature = 0.6;
      max_tokens = 512;
    };
    stt = {
      encoder = "${stt}/encoder.int8.onnx";
      decoder = "${stt}/decoder.int8.onnx";
      joiner = "${stt}/joiner.int8.onnx";
      tokens = "${stt}/tokens.txt";
    };
    tts = {
      model = "${tts}/model.onnx";
      tokens = "${tts}/tokens.txt";
      voices = "${tts}/voices.bin";
      espeak_data_dir = "${tts}/espeak-ng-data";
      speaker_id = 0;
      speed = 1.0;
    };
    vad = {
      model = "${vad}/silero_vad.onnx";
      threshold = 0.5;
      min_silence_ms = 250;
      min_speech_ms = 150;
    };
    audio = {
      capture_cmd = "pw-record --rate=16000 --channels=1 --format=s16 --raw -";
      playback_cmd = "pw-cat --playback --rate={rate} --channels=1 --format=s16 --raw -";
      capture_rate = 16000;
    };
    duplex = {
      trigger = "ptt";
      barge_in = true;
      barge_in_min_speech_ms = 250;
      end_of_turn_silence_ms = 600;
      max_utterance_s = 30;
    };
  };

  # The push-to-talk bind is delivered on the Lua surface
  # (user.ui.tomoe.extraConfig -> ~/.config/tomoe/init.lua) because the LIVE
  # session is the Rust/Lua compositor (flake input `tomoe-lua`; it links
  # liblua.so.5.4 and `tomoe msg version` returns wire 2). The Lisp surface is
  # the forward path for the Lisp session finix also ships — the policy entry
  # in modules/finix/desktop/tomoe-policy.lisp stays in place — but it is not
  # the running compositor today.
  #
  # Same shape as bolo.nix: one supervised command + one keybind table entry,
  # no code ([[principle:least-power]], [[principle:unix]] row 7).
  # process.service (not spawn) so a crash is respawned by tomoe's 1 Hz
  # supervision tick; restart "on_exit" is the superset of "on_failure".
  #
  # The command is an ARGV LIST with the subcommand as its own element:
  # tomoe's launcher does argv.split_first() then Command::new(program).args(args)
  # (crates/tomoe/src/process.rs:294 and 300-301 at the pinned tomoe-lua rev), so
  # a single element containing a space would try to exec a path with a space.
  #
  # The bind is PRESS-ONLY: baat's trigger is press-twice (arm, then
  # close/interrupt), so a release handler would double-fire — unlike bolo's
  # hold form, which declares both.
  #
  # Let-bound rather than inline at the extraConfig assignment: nested in that
  # assignment's mkIf it would add more cognitive complexity than the lint
  # allows.
  tomoeConfig = ''
    tomoe.process.service("baat", {
      command = {"${baatPkgs.baat}/bin/baat", "daemon"},
      restart = "on_exit",
    })
    tomoe.bind("${cfg.keybind}", {
      press = function() tomoe.spawn("${baatPkgs.baat}/bin/baat toggle") end,
    }, "Push-to-talk duplex voice chat (baat)")
  '';

  llmServiceConfig = lib.optionalString cfg.llmServer.enable ''
    tomoe.process.service("baat-llm", {
      command = {"${cfg.llmServer.path}/start.sh"},
      restart = "on_exit",
    })
  '';
in {
  options.user.programs.baat = {
    enable = lib.mkEnableOption "baat duplex voice bot (daemon + thin client)";

    provider = lib.mkOption {
      type = lib.types.enum ["cpu" "cuda"];
      default = "cpu";
      description = ''
        sherpa-onnx execution provider written to the manifest. Mirrors
        bolo.provider: cpu is the safe default, cuda runs STT/TTS on the GPU.
      '';
    };

    keybind = lib.mkOption {
      type = lib.types.str;
      default = "Mod+space"; # tomoe Mod = Alt; only Super+space is otherwise bound
      description = ''
        Tomoe push-to-talk bind (press-only): each press runs `baat toggle`,
        which arms, closes, or interrupts the turn. baat's trigger is
        press-twice, not bolo's hold form, so no release handler is declared.
      '';
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "${config.user.homeDirectory}/.paseo/models/local-speech";
      description = "Directory holding the on-disk sherpa-onnx STT/TTS/VAD models.";
    };

    llm = {
      baseUrl = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8888/v1";
        description = "OpenAI-compatible endpoint root; /chat/completions is appended.";
      };
      model = lib.mkOption {
        type = lib.types.str;
        default = "qwen3.8-27b-exl3-3.5bpw-wm";
        description = "Model id sent in the chat request (the id the local server reports).";
      };
    };

    manifestPath = lib.mkOption {
      type = lib.types.str;
      default = ".config/baat/manifest.json";
      description = ''
        Home-relative destination for the generated manifest (the daemon's
        second resolution path, $XDG_CONFIG_HOME/baat/manifest.json, resolves
        here when XDG_CONFIG_HOME is unset).
      '';
    };

    llmServer = {
      enable = lib.mkEnableOption ''
        supervising the local exllamav3 LLM endpoint: on means instant answers
        from the first press but ~16 GB of VRAM held permanently, off means
        starting the endpoint yourself when you want to talk
      '';
      path = lib.mkOption {
        type = lib.types.str;
        default = "/home/y0usaf/dev/sandbox/Qwen3.8-27B-DFlash2-EXL3-5.0bpw";
        description = "Deployment kit directory; its start.sh is the supervised command.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [baatPkgs.baat];

    # The manifest is produced by the system from the options above
    # ([[principle:unix]] row 7), never hand-edited.
    manzil.users."${config.user.name}".files."${cfg.manifestPath}".source =
      pkgs.writeText "baat-manifest" (builtins.toJSON manifest);

    # The bind table entry plus the daemon service (tomoeConfig) and the
    # optional local LLM endpoint (llmServiceConfig), concatenated into one Lua
    # prelude; both strings and their mechanism notes live at the end of the
    # module's let block.
    user.ui.tomoe.extraConfig =
      lib.mkIf config.user.ui.tomoe.enable (tomoeConfig + llmServiceConfig);
  };
}
