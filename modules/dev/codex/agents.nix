{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    manzil.users."${config.user.name}".files = {
      ".local/share/codex/agents/explorer.toml" = {
        generator = config.lib.generators.toTOML;
        value = {
          model = "gpt-5.4";
          model_reasoning_effort = "xhigh";
        };
      };
      ".local/share/codex/agents/worker.toml" = {
        generator = config.lib.generators.toTOML;
        value = {
          model = "gpt-5.4";
          model_reasoning_effort = "xhigh";
        };
      };
    };
  };
}
