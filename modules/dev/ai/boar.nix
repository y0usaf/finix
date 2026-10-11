{
  config,
  lib,
  pkgs,
  flakeInputs,
  ...
}: let
  agentFiles = dir: {
    "${dir}/settings.json" = {
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
        fusion.opus-sol = {
          lead = "anthropic/claude-opus-5-5";
          sidekick = "openai-codex/gpt-6.1-sol";
        };
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
    "${dir}/models.json" = {
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
    "${dir}/mcp.json" = {
      generator = lib.generators.toJSON {};
      value.mcpServers.donsetch = {
        command = lib.getExe flakeInputs.pi-donsetch.packages.${pkgs.stdenv.hostPlatform.system}.donsetch;
        args = ["mcp"];
      };
    };
  };
in {
  finix.persistence.allowlist.users.${config.user.name}.directories = [
    ".local/state/boar"
    ".local/state/boar-rs"
    ".local/state/crest-auth"
  ];
  environment.systemPackages = [
    flakeInputs.boar-rs.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
  manzil.users."${config.user.name}".files =
    agentFiles ".local/state/boar/agent"
    // agentFiles ".local/state/boar-rs/agent";
}
