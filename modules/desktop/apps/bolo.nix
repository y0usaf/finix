{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.programs.bolo;

  boloPkgs = flakeInputs.bolo.packages.${pkgs.stdenv.hostPlatform.system};

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

  manifest = pkgs.writeText "bolo-manifest" (builtins.toJSON {
    version = 1;
    active = cfg.model;
    language = cfg.language;
    pipe_to = cfg.pipeTo;
    models = lib.mapAttrsToList (name: m: {
      inherit name;
      inherit (m) engine;
      encoder = "${modelDir name}/encoder.int8.onnx";
      decoder = "${modelDir name}/decoder.int8.onnx";
      joiner = "${modelDir name}/joiner.int8.onnx";
      tokens = "${modelDir name}/tokens.txt";
    })
    models;
  });

  runtimeDeps = [
    pkgs.pipewire # pw-record
    pkgs.wl-clipboard # wl-copy
    pkgs.libnotify # notify-send
  ];

  # bolod is spawned by the compositor, whose PATH doesn't carry these.
  bolod = pkgs.symlinkJoin {
    name = "bolod-wrapped";
    paths = [boloPkgs.bolod];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/bolod --prefix PATH : ${lib.makeBinPath runtimeDeps}
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
    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      description = "Dictation language hint recorded in the manifest.";
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
        Tomoe push-to-talk bind (hold form): key-down spawns bolo to start
        recording, key-up spawns it again to stop and transcribe.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [boloPkgs.bolo];

    # uinput node + input-group access for dotool autofill. Same rule asryx
    # installs; duplicate lines are harmless while both are enabled.
    boot.kernelModules = lib.mkIf cfg.autofill ["uinput"];
    services.udev.extraRules = lib.mkIf cfg.autofill ''
      KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
    '';

    # Same autofill pipeline as asryx: flatten to one line, release all
    # modifiers on dotool's virtual keyboard first (tomoe merges xkb state).
    user.programs.bolo.pipeTo = lib.mkIf cfg.autofill (lib.mkDefault (
      "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntype '; tr '\\n' ' '; } | dotool"
    ));

    manzil.users."${config.user.name}" = {
      files =
        {
          ".config/bolo/manifest.json".source = manifest;
        }
        # Model files land where the manifest points.
        // lib.foldl' (acc: name:
          acc
          // lib.mapAttrs' (f: src:
            lib.nameValuePair ".local/share/bolo/models/${name}/${f}" {source = src;})
          models.${name}.files) {}
        (lib.attrNames models)
        // lib.optionalAttrs config.user.ui.niri.enable {
          ".config/niri/config.kdl".value = {
            binds."${cfg.keybind}" = {spawn = "${boloPkgs.bolo}/bin/bolo";};
            # Session-scoped daemon start (DESIGN.md locked decision):
            # compositor child inherits XDG_RUNTIME_DIR + pipewire socket.
            spawn-at-startup = [["${bolod}/bin/bolod"]];
          };
        };
    };

    # Tomoe: autostart at config load + push-to-talk hold bind.
    user.ui.tomoe.extraConfig = lib.mkIf config.user.ui.tomoe.enable ''
      tomoe.spawn("${bolod}/bin/bolod")
      tomoe.bind("${cfg.tomoeKeybind}", {
        press = function() tomoe.spawn("${boloPkgs.bolo}/bin/bolo") end,
        release = function() tomoe.spawn("${boloPkgs.bolo}/bin/bolo") end,
      }, "Push-to-talk speech-to-text (bolo)")
    '';
  };
}
