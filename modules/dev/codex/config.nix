{
  config,
  lib,
  ...
}: let
  codexCfg = config.user.dev.codex;
in {
  config = lib.mkIf codexCfg.enable {
    patchix = {
      enable = true;
      users."${config.user.name}".patches.".local/share/codex/config.toml" = {
        format = "toml";
        clobber = true;
        value =
          {
            approval_policy = "never";
            sandbox_mode = "danger-full-access";
            service_tier = "default";
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
          // lib.optionalAttrs (codexCfg.providers != {}) {
            model_providers =
              lib.mapAttrs (_: provider: {
                inherit (provider) name;
                base_url = provider.baseUrl;
                env_key = provider.envKey;
                # Codex removed chat-completions support; only the
                # Responses API remains (openai/codex#7782).
                wire_api = "responses";
              })
              codexCfg.providers;
          }
          // lib.optionalAttrs (codexCfg.defaultProvider != null) {
            model_provider = codexCfg.defaultProvider;
          }
          // codexCfg.settings
          // {
            inherit (codexCfg) model;
          };
      };
    };
  };
}
