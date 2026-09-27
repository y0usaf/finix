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
    ".prime"
  ];
  environment.systemPackages = [
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".prime-agent
  ];

  manzil.users."${config.user.name}".files = {
    ".prime/agent/settings.json" = {
      generator = toJSON;
      value = {
        inherit (catalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
        rlmMaxDepth = 999;
        hideThinkingBlock = true;
        packages = [
          "/home/y0usaf/dev/maintaining/pi-flake/extensions/pi-vercel-ai-gateway"
        ];
      };
    };

    ".prime/agent/models.json" = {
      generator = toJSON;
      value = catalog.models;
    };

    ".prime/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.ethics}\n\n${config.user.dev.prompts.noTests}\n\n${config.user.dev.prompts.noComments}\n";
  };
}
