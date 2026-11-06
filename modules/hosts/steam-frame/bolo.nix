{
  config,
  lib,
  pkgs,
  inputPackages,
  ...
}: let
  user = config.user.name;
  inherit (import ../../desktop/apps/bolo.data.nix) model vocabulary;
  modelDir = "/home/${user}/.local/share/bolo/models/${model.name}";
  hashes = builtins.mapAttrs (_: hash:
    builtins.convertHash {
      inherit hash;
      toHashFormat = "base16";
    })
  model.hashes;

  fetchModel = pkgs.writeShellScript "bolo-fetch-model" ''
    set -eu
    mkdir -p ${modelDir}
    ${lib.concatStrings (lib.mapAttrsToList (file: hash: ''
        if [ ! -s ${modelDir}/${file} ]; then
          ${pkgs.curl}/bin/curl -fL --retry 5 --retry-delay 10 --retry-connrefused -o ${modelDir}/${file}.part ${model.url}/${file}
          echo "${hash}  ${modelDir}/${file}.part" | ${pkgs.coreutils}/bin/sha256sum -c --quiet
          mv ${modelDir}/${file}.part ${modelDir}/${file}
        fi
      '')
      hashes)}
  '';
in {
  environment.systemPackages = [
    inputPackages.bolo.bolo
    inputPackages.bolo.bolod
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
        ExecStart = "${inputPackages.bolo.bolod}/bin/bolod";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };

  manzil.users.${user}.files.".config/bolo/manifest.json" = {
    generator = builtins.toJSON;
    value = {
      version = 1;
      active = model.name;
      language = "en";
      provider = "cpu";
      threads = null;
      pipe_to = "{ printf 'keyup leftctrl rightctrl leftalt rightalt leftshift rightshift leftmeta rightmeta\\ntypedelay 1\\ntypehold 1\\ntype '; tr '\\n' ' '; } | ${pkgs.dotool}/bin/dotool";
      models = [
        {
          inherit (model) name engine;
          encoder = "${modelDir}/encoder.int8.onnx";
          decoder = "${modelDir}/decoder.int8.onnx";
          joiner = "${modelDir}/joiner.int8.onnx";
          tokens = "${modelDir}/tokens.txt";
        }
      ];
      vocabulary = lib.mapAttrsToList (word: aliases: {inherit word aliases;}) vocabulary;
      vocab_fuzzy = 0.85;
    };
  };
}
