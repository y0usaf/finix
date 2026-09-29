{
  config,
  lib,
  pkgs,
  boloPackages,
  ...
}: let
  user = config.user.name;
  model = "parakeet-v3-int8";
  modelDir = "/home/${user}/.local/share/bolo/models/${model}";
  hfBase = "https://huggingface.co/csukuangfj/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/resolve/main";
  hashes = {
    "decoder.int8.onnx" = "179e50c43d1a9de79c8a24149a2f9bac6eb5981823f2a2ed88d655b24248db4e";
    "encoder.int8.onnx" = "acfc2b4456377e15d04f0243af540b7fe7c992f8d898d751cf134c3a55fd2247";
    "joiner.int8.onnx" = "3164c13fc2821009440d20fcb5fdc78bff28b4db2f8d0f0b329101719c0948b3";
    "tokens.txt" = "d58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d";
  };

  fetchModel = pkgs.writeShellScript "bolo-fetch-model" ''
    set -eu
    mkdir -p ${modelDir}
    ${lib.concatStrings (lib.mapAttrsToList (file: hash: ''
        if [ ! -s ${modelDir}/${file} ]; then
          ${pkgs.curl}/bin/curl -fL --retry 5 --retry-delay 10 --retry-connrefused -o ${modelDir}/${file}.part ${hfBase}/${file}
          echo "${hash}  ${modelDir}/${file}.part" | ${pkgs.coreutils}/bin/sha256sum -c --quiet
          mv ${modelDir}/${file}.part ${modelDir}/${file}
        fi
      '')
      hashes)}
  '';
in {
  environment.systemPackages = [
    boloPackages.bolo
    boloPackages.bolod
  ];

  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
  '';

  systemd = {
    services.bolo-models = {
      description = "Fetch bolo's speech model into the ${user} home";
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      unitConfig.RequiresMountsFor = "/home/${user}";
      serviceConfig = {
        Type = "oneshot";
        User = user;
        ExecStart = fetchModel;
        ExecStartPost = "-${config.systemd.package}/bin/systemctl --user --machine=${user}@.host start bolod.service";
        Restart = "on-failure";
        RestartSec = "30s";
      };
    };

    user.services.bolod = {
      description = "bolo speech-to-text daemon";
      wantedBy = ["default.target"];
      unitConfig.ConditionPathExists = "${modelDir}/tokens.txt";
      path = [
        pkgs.bash
        pkgs.coreutils
      ];
      serviceConfig = {
        ExecStart = "${boloPackages.bolod}/bin/bolod";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };

  manzil.users.${user}.files.".config/bolo/manifest.json" = {
    generator = builtins.toJSON;
    value = {
      version = 1;
      active = model;
      language = "en";
      provider = "cpu";
      threads = null;
      pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | ${pkgs.dotool}/bin/dotool";
      models = [
        {
          name = model;
          engine = "sherpa-onnx-transducer";
          encoder = "${modelDir}/encoder.int8.onnx";
          decoder = "${modelDir}/decoder.int8.onnx";
          joiner = "${modelDir}/joiner.int8.onnx";
          tokens = "${modelDir}/tokens.txt";
        }
      ];
      vocabulary =
        lib.mapAttrsToList (word: aliases: {inherit word aliases;})
        {
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
    };
  };
}
