{
  config,
  lib,
  genLib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    bayt.users."${config.user.name}".files = {
      ".codex/agents/explorer.toml" = {
        generator = genLib.toTOML;
        value = {
          model = "gpt-5.4";
          model_reasoning_effort = "high";
        };
      };
      ".codex/agents/worker.toml" = {
        generator = genLib.toTOML;
        value = {
          model = "gpt-5.4";
          model_reasoning_effort = "high";
        };
      };
    };
  };
}
