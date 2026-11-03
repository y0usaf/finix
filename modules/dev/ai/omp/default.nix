{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
  ompSecret = pkgs.writeShellScriptBin "omp-secret" ''
    PATH=${lib.makeBinPath [pkgs.age]}:$PATH exec ${pkgs.bun}/bin/bun ${./secrets}/omp-secret.ts "$@"
  '';
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".omp"
    ".local/share/omp"
    ".local/state/omp-secrets"
  ];

  environment.systemPackages = [pkgs.jq pkgs.age ompSecret];

  manzil.users.${config.user.name}.files = {
    ".omp/agent/config.yml" = {
      generator = lib.generators.toYAML {};
      value = {
        defaultThinkingLevel = catalog.ompThinkingLevel;
        advisor.enabled = true;
        startup.checkUpdate = false;
        setupVersion = 2;
        symbolPreset = "unicode";
        theme.dark = "titanium";
        composer.tokenRate = false;
        disabledExtensions = [];
        dev.autoqaConsent = "granted";
        colorBlindMode = false;
        hideThinkingBlock = true;
        statusLine = {
          sessionAccent = true;
          contextLine = "embedded";
        };
        tui = {
          renderMermaid = true;
          scrollbackRebuild = true;
        };
        display = {
          shimmer = "classic";
          smoothStreaming = true;
        };
        task = {
          showResolvedModelBadge = false;
          eager = "preferred";
          enableLsp = false;
        };
        edit.mode = "hashline";
        astGrep.enabled = true;
        github.enabled = true;
        eval.js = false;
        codexResets.autoRedeem = "no";
        title.icons = "nf+emoji";
        interruptMode = "immediate";
        modelRoles = {
          default = "${catalog.defaultProvider}/${catalog.defaultModel}";
          advisor = catalog.advisorModel;
          smol = catalog.smolModel;
          judge = catalog.judgeModel;
        };
        retry.fallbackChains = catalog.fallbackChains;
        extensions = [
          "${flakeInputs.pi-chronobreak}"
          "${flakeInputs.pi-recap}"
          "${flakeInputs.pi-donsetch.packages.${pkgs.stdenv.hostPlatform.system}.default}"
          "${./code-mode.ts}"
          "${./compact-eval.ts}"
          "${./work-fold.ts}"
          "${./box-commands.ts}"
          "${./cwd.ts}"
          "${./secrets}/secrets.ts"
          "${./crest-auth.ts}"
          "${./optchat}/extension.ts"
        ];
      };
    };
    ".omp/config.json" = {
      generator = toJSON;
      value = {
        terminal_width_percent = 50;
        panel_width_percent = 13;
        ascii = true;
        keybinds = {
          project_next = "ctrl+l";
          project_prev = "ctrl+h";
          session_next = "ctrl+j";
          session_prev = "ctrl+k";
        };
      };
    };
    ".omp/agent/settings.json" = {
      generator = toJSON;
      value = {
        inherit (catalog) defaultProvider;
        inherit (catalog) defaultModel;
        defaultThinkingLevel = catalog.ompThinkingLevel;
        inherit (catalog) enabledModels;
        packages = [];
      };
    };
    ".omp/agent/models.yml" = {
      generator = lib.generators.toYAML {};
      value = import ./models.data.nix;
    };
    ".omp/agent/models.json" = {
      generator = toJSON;
      value = catalog.models;
    };
    ".omp/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.shared}\n";
  };
}
