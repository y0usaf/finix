{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  catalog = config.user.dev.modelCatalog;
  cfg = config.user.dev.ompBox;
  state = "${home}/.local/state/omp-box";
  json = lib.generators.toJSON {};
  crest = flakeInputs.crest.packages.${pkgs.stdenv.hostPlatform.system};

  proxy = pkgs.writers.writePython3Bin "omp-gateway-proxy" {} (builtins.readFile ../../../omp-box/gateway-proxy.py);
  gatewayUrl = "http://10.0.2.2:8899";
  files = {
    models = pkgs.writeText "models.json" (json catalog.models);
    modelKeys = pkgs.writeText "models.yml" ''
      providers:
        vercel-ai-gateway:
          baseUrl: ${gatewayUrl}
          apiKey: "!echo unused"
    '';
    settings = pkgs.writeText "settings.json" (json {
      inherit (catalog) defaultProvider defaultModel defaultThinkingLevel;
      inherit (catalog) enabledModels;
      packages = [];
    });
    config = pkgs.writeText "config.yml" ''
      setupVersion: 2
      startup:
        setupWizard: false
      defaultThinkingLevel: ${catalog.defaultThinkingLevel}
      modelRoles:
        advisor: vercel-ai-gateway/openai/gpt-5.6-luna
        default: ${catalog.defaultProvider}/${catalog.defaultModel}
      advisor:
        enabled: false
      extensions: []
    '';
    appendSystem = pkgs.writeText "APPEND_SYSTEM.md" "${config.user.dev.prompts.shared}\n";
  };

  guest = flakeInputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      ompBox = {
        inherit user files;
        shares = cfg.shares;
        sharesDir = "${state}/shares";
        inherit crest;
        nativesDir = "${state}/natives";
        inherit (flakeInputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}) omp;
      };
    };
    modules = [
      {nixpkgs.pkgs = pkgs;}
      flakeInputs.microvm.nixosModules.microvm
      ../../../omp-box/guest.nix
    ];
  };

  pkg = pkgs.callPackage ../../../omp-box {
    inherit user;
    inherit (cfg) shares;
    omp = flakeInputs.oh-my-pi.packages.${pkgs.stdenv.hostPlatform.system}.omp;
  };
in {
  options.user.dev.ompBox.shares = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Absolute host paths shared with the omp microVM.";
  };

  config = {
    finix.persistence = {
      allowlist.users.${user}.directories = [".local/state/omp-box"];
      homeServices = ["omp-box" "omp-box-grants" "omp-box-proxy"];
    };
    environment.systemPackages = [pkg];
    system.build.ompBoxRunner = guest.config.microvm.declaredRunner;

    finit.services.omp-box-grants = {
      description = "re-apply omp box folder grants";
      user = user;
      reload-signal = "none";
      log = true;
      environment = {
        HOME = home;
        XDG_STATE_HOME = "${home}/.local/state";
      };
      command = "${pkgs.writeShellScript "omp-box-grants" ''
        while :; do
          if ${pkgs.openssh}/bin/ssh -q -p 22422 -i ${state}/id_ed25519 \
               -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
               -o BatchMode=yes -o ConnectTimeout=1 ${user}@127.0.0.1 \
               mountpoint -q /mnt/shares 2>/dev/null; then
            ${pkg}/bin/omp-box reconcile
            ${pkgs.coreutils}/bin/sleep 30
          else
            ${pkgs.coreutils}/bin/sleep 2
          fi
        done
      ''}";
    };

    finit.services.omp-box-proxy = {
      description = "omp gateway proxy";
      user = user;
      reload-signal = "none";
      log = true;
      environment = {
        GATEWAY_KEY_FILE = "${home}/Tokens/AI_GATEWAY_API_KEY.txt";
        HOME = home;
      };
      command = "${proxy}/bin/omp-gateway-proxy";
    };

    finit.services.omp-box = {
      description = "omp NixOS microVM";
      user = user;
      reload-signal = "none";
      environment = {
        HOME = home;
      };
      command = "${pkgs.writeShellScript "omp-box-run" ''
        mkdir -p ${state}/shares ${state}/grants ${state}/natives ${home}/.omp/natives
        cp -al ${home}/.omp/natives/. ${state}/natives/ || cp -a ${home}/.omp/natives/. ${state}/natives/
        for _ in $(seq 60); do ${pkgs.iproute2}/bin/ss -Hltn 'sport = :22422' | grep -q . || break; sleep 0.5; done
        rm -f ${state}/omp-box.sock
        cd ${state}
        exec ${guest.config.microvm.declaredRunner}/bin/microvm-run
      ''}";
    };
  };
}
