{
  config,
  lib,
  pkgs,
  flakeInputs,
  inputPackages,
  generators,
  ...
}: let
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
  secrets = generators.sourceDir pkgs "secrets" (import ./secrets.data.nix);
  # omp loads its extensions through these links, not their store paths, so a switch that rebuilds one leaves
  # config.yml's paths alone and running sessions see no "newly enabled" extension to restart for. omp-bot's
  # env (the omp_bot module) names its extensions by the same links, so a bot loads each once.
  extDir = "${config.users.users.${config.user.name}.home}/.omp/agent/ext";
  extLinks =
    lib.genAttrs ["pi-chronobreak" "pi-recap" "omp-bot"] (name: "${flakeInputs.${name}}")
    // {
      pi-donsetch = "${inputPackages.pi-donsetch.default}";
      "compact-eval.ts" = generators.sourceFile "compact-eval.ts" (generators.ts.render (import ./compact-eval.data.nix generators.ts));
      "work-fold.ts" = generators.sourceFile "work-fold.ts" (generators.ts.render (import ./work-fold.data.nix generators.ts));
      "chat-look.ts" = generators.sourceFile "chat-look.ts" (generators.ts.render (import ./chat-look.data.nix generators.ts));
      "box-commands.ts" = generators.sourceFile "box-commands.ts" (generators.ts.render (import ./box-commands.data.nix generators.ts));
      "cwd.ts" = generators.sourceFile "cwd.ts" (generators.ts.render (import ./cwd.data.nix generators.ts));
      secrets = "${secrets}";
      "crest-auth.ts" = generators.sourceFile "crest-auth.ts" (generators.ts.render (import ./crest-auth.data.nix generators.ts));
      optchat = generators.sourceDir pkgs "optchat" (import ./optchat/optchat.data.nix {inherit generators;});
    };
  ompSecret = pkgs.writeShellScriptBin "omp-secret" ''
    PATH=${lib.makeBinPath [pkgs.age]}:$PATH exec ${pkgs.bun}/bin/bun ${secrets}/omp-secret.ts "$@"
  '';
in {
  user.persist.directories = [
    ".omp"
    ".local/share/omp"
    ".local/state/omp-secrets"
  ];

  environment.systemPackages = [pkgs.jq pkgs.age ompSecret];

  user.files =
    lib.mapAttrs' (name: source: lib.nameValuePair ".omp/agent/ext/${name}" {source = "${source}";}) extLinks
    // {
      ".omp/agent/config.yml" = {
        generator = lib.generators.toYAML {};
        value = {
          defaultThinkingLevel = catalog.ompThinkingLevel;
          advisor.enabled = true;
          advisor.reviewMode = "agent-end";
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
            task = catalog.taskModel;
          };
          retry.fallbackChains = catalog.fallbackChains;
          extensions = map (path: "${extDir}/${path}") [
            "pi-chronobreak"
            "pi-recap"
            "pi-donsetch"
            "omp-bot/omp/code-mode.ts"
            "compact-eval.ts"
            "work-fold.ts"
            "chat-look.ts"
            "box-commands.ts"
            "cwd.ts"
            "secrets/secrets.ts"
            "crest-auth.ts"
            "optchat/extension.ts"
            "omp-bot/omp/ompd.ts"
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
      ".omp/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.shared}\n\n${catalog.taskNote}\n";
    };
}
