{
  config,
  lib,
  ...
}: let
  codexCfg = config.user.dev.codex;
  vercelAiGatewayCfg = codexCfg.providers."vercel-ai-gateway";
in {
  config = lib.mkIf codexCfg.enable {
    patchix = {
      enable = true;
      users."${config.user.name}".patches.".codex/config.toml" = {
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
          // lib.optionalAttrs vercelAiGatewayCfg.enable {
            model_provider = "vercel-ai-gateway";
            model_providers."vercel-ai-gateway" = {
              name = "Vercel AI Gateway";
              base_url = vercelAiGatewayCfg.baseUrl;
              env_key = "AI_GATEWAY_API_KEY";
              wire_api = vercelAiGatewayCfg.wireApi;
            };
          }
          // codexCfg.settings
          // {
            inherit (codexCfg) model;
          };
      };
    };

    manzil.users."${config.user.name}".files = lib.optionalAttrs (vercelAiGatewayCfg.enable && vercelAiGatewayCfg.apiKeyFile != null) {
      ".config/nushell/env.nu" = {
        text = lib.mkAfter ''
          $env.AI_GATEWAY_API_KEY = (open "${vercelAiGatewayCfg.apiKeyFile}" | str trim)
        '';
      };
    };
  };
}
