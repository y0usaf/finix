{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.codex.enable {
    manzil.users."${config.user.name}".files = {
      ".codex/config.toml" = {
        generator = config.lib.generators.toTOML;
        value =
          {
            approval_policy = "never";
            sandbox_mode = "danger-full-access";
            fastMode = false;
            features = {
              multi_agent = true;
              steer = true;
              unified_exec = true;
            };
            otel = {
              exporter = "none";
              log_user_prompt = false;
              environment = "dev";
            };
            tui = {
              alternate_screen = "never";
            };
            agents = {
              explorer = {
                description = "Use for codebase discovery and analysis. Prioritize reading, tracing, and precise explanations before making edits.";
                config_file = "./agents/explorer.toml";
              };
              worker = {
                description = "Use for implementation and execution tasks. Make targeted changes, run checks, and return concrete results.";
                config_file = "./agents/worker.toml";
              };
            };
          }
          // config.user.dev.codex.settings
          // {
            inherit (config.user.dev.codex) model;
          };
      };
    };
  };
}
