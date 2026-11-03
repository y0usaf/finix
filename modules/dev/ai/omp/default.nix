{
  config,
  lib,
  pkgs,
  flakeInputs,
  generators,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".omp"
    ".local/share/omp"
  ];

  environment.systemPackages = [pkgs.jq];

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
          "${generators.sourceFile "code-mode.ts" (generators.tsSource (import ./code-mode.data.nix))}"
          "${generators.sourceFile "compact-eval.ts" (generators.tsSource (import ./compact-eval.data.nix))}"
          "${generators.sourceFile "work-fold.ts" (generators.tsSource (import ./work-fold.data.nix))}"
          "${generators.sourceFile "box-commands.ts" (generators.tsSource (import ./box-commands.data.nix))}"
          "${generators.sourceFile "crest-auth.ts" (generators.tsSource (import ./crest-auth.data.nix))}"
          "${generators.sourceDir pkgs "optchat" (import ./optchat/optchat.data.nix {inherit generators;})}/extension.ts"
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
