{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/state/boar"
  ];
  manzil.users."${config.user.name}".files = {
    ".local/state/boar/agent/settings.json" = {
      generator = lib.generators.toJSON {};
      value = {
        defaultTools = ["+codemode"];
        codemode.mode = "only";
        subagents = {
          depth = -1;
          concurrency = -1;
          models = ["anthropic/claude-sonnet-5-5" "anthropic/claude-haiku-5-5"];
        };
        memory.model = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash";
        keys =
          {
            furrowNew = ["alt+t" "ctrl+n"];
            furrowRename = ["alt+r"];
            furrowClose = ["alt+w" "ctrl+shift+w" "ctrl+delete"];
            furrowNext = ["alt+." "ctrl+."];
            furrowPrev = ["alt+," "ctrl+,"];
            quit = ["ctrl+shift+d"];
          }
          // lib.listToAttrs (map (n: {
            name = "furrow${toString n}";
            value = ["alt+${toString n}" "ctrl+${toString n}"];
          }) (lib.range 1 9));
      };
    };
    ".local/state/boar/agent/models.json" = {
      generator = lib.generators.toJSON {};
      value.providers.anthropic.models = [
        {
          id = "claude-haiku-5-5";
          name = "Claude Haiku 5.5";
          reasoning = true;
          input = ["text" "image"];
          contextWindow = 200000;
          maxTokens = 64000;
          cost = {
            input = 1;
            output = 5;
            cacheRead = 0.1;
            cacheWrite = 1.25;
          };
        }
      ];
    };
    ".local/state/boar/agent/mcp.json" = {
      generator = lib.generators.toJSON {};
      value.mcpServers.donsetch = {
        command = lib.getExe flakeInputs.pi-donsetch.packages.${pkgs.stdenv.hostPlatform.system}.donsetch;
        args = ["mcp"];
      };
    };
  };
}
