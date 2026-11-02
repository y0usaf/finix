{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".omp"
  ];

  environment.systemPackages = [pkgs.jq];

  manzil.users."${config.user.name}".files = {
    ".omp/agent/config.yml" = {
      type = "merge";
      format = "yaml";
      clobber = true;
      value = {
        defaultThinkingLevel = catalog.ompThinkingLevel;
        advisor.enabled = true;
        startup.checkUpdate = false;
        modelRoles.default = "${catalog.defaultProvider}/${catalog.defaultModel}";
        modelRoles.advisor = catalog.advisorModel;
        modelRoles.smol = catalog.smolModel;
        modelRoles.judge = catalog.judgeModel;
        retry.fallbackChains = catalog.fallbackChains;
        extensions = [
          "${flakeInputs.pi-chronobreak}"
          "${flakeInputs.pi-recap}"
          "${flakeInputs.pi-donsetch.packages."${pkgs.stdenv.hostPlatform.system}".default}"
          "${./omp-code-mode.ts}"
          "${./omp-compact-eval.ts}"
          "${./omp-work-fold.ts}"
          "${./omp-box-commands.ts}"
          "${./omp-crest-auth.ts}"
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
    ".omp/agent/models.json" = {
      generator = toJSON;
      value = catalog.models;
    };
    ".omp/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.shared}\n";
  };
}
