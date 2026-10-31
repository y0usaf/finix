{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  user = config.user.name;
  home = config.users.users.${user}.home;
  uid = config.users.users.${user}.uid;
  catalog = config.user.dev.modelCatalog;
  cfg = config.user.dev.ompBox;
  state = "${home}/.local/state/omp-box";
  json = lib.generators.toJSON {};

  files = {
    models = pkgs.writeText "models.json" (json catalog.models);
    settings = pkgs.writeText "settings.json" (json {
      inherit (catalog) defaultProvider defaultModel defaultThinkingLevel;
      inherit (catalog) enabledModels;
      packages = [];
    });
    config = pkgs.writeText "config.yml" ''
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
        shares = ["${home}/.omp/natives"] ++ cfg.shares;
        sharesDir = "${state}/shares";
      };
    };
    modules = [
      { nixpkgs.pkgs = pkgs; }
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
    finix.persistence.allowlist.users.${user}.directories = [".local/state/omp-box"];
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
          fi
          ${pkgs.coreutils}/bin/sleep 30
        done
      ''}";
    };

    finit.services.omp-box = {
      description = "omp NixOS microVM";
      user = user;
      reload-signal = "none";
      environment = {
        HOME = home;
        XDG_RUNTIME_DIR = "/run/user/${toString uid}";
      };
      command = "${pkgs.writeShellScript "omp-box-run" ''
        mkdir -p ${state}/shares ${state}/grants ${home}/.omp/natives
        rm -f ${state}/omp-box.sock ${state}/nixos.sock
        cd ${state}
        exec ${guest.config.microvm.declaredRunner}/bin/microvm-run
      ''}";
    };
  };
}
