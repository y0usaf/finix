{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".prime"
  ];
  environment.systemPackages = [
    flakeInputs.pi-flake.packages."${pkgs.stdenv.hostPlatform.system}".prime-agent
  ];

  manzil.users."${config.user.name}".files = {
    ".prime/agent/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        inherit (config.user.dev.modelCatalog) defaultProvider defaultModel defaultThinkingLevel enabledModels;
        rlmMaxDepth = 999;
        hideThinkingBlock = true;
        packages = [];
      };
    };

    ".prime/agent/models.json" = {
      generator = lib.generators.toJSON {};
      value = config.user.dev.modelCatalog.models;
    };

    ".prime/agent/APPEND_SYSTEM.md".text = "${config.user.dev.prompts.shared}\n";
  };
}
