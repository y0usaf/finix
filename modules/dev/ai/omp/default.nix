{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  cfg = config.user.dev.omp;
  catalog = config.user.dev.modelCatalog;
  toJSON = lib.generators.toJSON {};
in {
  options.user.dev.omp = {
    enable = lib.mkEnableOption "omp (oh-my-pi) coding agent CLI";

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = "Keys merged into ~/.omp/config.json.";
    };
  };

  config = lib.mkIf cfg.enable {
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
        value = cfg.settings;
      };
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
