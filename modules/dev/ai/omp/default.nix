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
  options.user.dev.omp.enable = lib.mkEnableOption "omp (oh-my-pi) coding agent CLI";

  config = lib.mkIf config.user.dev.omp.enable {
    finix.persistence.allowlist.users.${config.user.name}.directories = [
      ".omp"
    ];
    environment.systemPackages = [
      flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".omp-full
    ];

    manzil.users."${config.user.name}".files = {
      ".omp/agent/config.yml" = {
        type = "merge";
        format = "yaml";
        clobber = true;
        value = {
          inherit (catalog) defaultThinkingLevel;
          advisor.enabled = false;
          modelRoles.default = "${catalog.defaultProvider}/${catalog.defaultModel}";
          modelRoles.advisor = "vercel-ai-gateway/openai/gpt-5.6-luna";
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
      ".omp/agent/rules/tldr.md".text = ''
        ---
        {"condition":["(?s).{2000,}"],"interruptMode":"never","scope":"text"}---

        TL;DR: summarize the preceding response in 3-5 concise bullets.
      '';
      ".omp/agent/settings.json" = {
        generator = toJSON;
        value = {
          inherit (catalog) defaultProvider;
          inherit (catalog) defaultModel;
          inherit (catalog) defaultThinkingLevel;
          inherit (catalog) enabledModels;
          packages = [
            "/home/y0usaf/dev/maintaining/pi-flake/extensions/pi-vercel-ai-gateway"
          ];
        };
      };
      ".omp/agent/models.json" = {
        generator = toJSON;
        value = catalog.models;
      };
      ".omp/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.ethics}\n\n${config.user.dev.prompts.noTests}\n\n${config.user.dev.prompts.noComments}\n";
    };
  };
}
