{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    manzil.users."${config.user.name}".files = {
      ".codex/agents/explorer.toml" = {
        generator = config.lib.generators.toTOML;
        value = {
          model = "gpt-5.5";
          model_reasoning_effort = "high";
        };
      };
      ".codex/agents/worker.toml" = {
        generator = config.lib.generators.toTOML;
        value = {
          model = "gpt-5.5";
          model_reasoning_effort = "high";
        };
      };
    };
  };
}
