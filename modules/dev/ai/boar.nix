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
        disabledExtensions = ["contain"];
        codemode.mode = "only";
        subagents = {
          concurrency = -1;
          roles = {
            scout = "fusion/opus-sol";
            ship = "fusion/opus-sol";
          };
          defaultRole = "scout";
        };
        defaultProvider = "fusion";
        defaultModel = "opus-sol";
        defaultThinkingLevel = "xhigh";
        fallbackProvider = "openai-codex";
        fallbackModel = "gpt-6.1-sol";
        messages.whenBusy = "steer";
        memory.model = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-1017";
        fusion.opus-sol = {
          lead = "anthropic/claude-opus-5-5";
          peer = "openai-codex/gpt-6.1-sol";
          gate = ["git commit" "git push" "switch-to-configuration switch"];
        };
        ascii = true;
        toolView = "headers";
        keys = {
          furrowNew = ["alt+t" "ctrl+n"];
          furrowRename = ["alt+r"];
          furrowClose = ["alt+w" "ctrl+shift+w" "ctrl+delete"];
          furrowNext = ["alt+." "ctrl+."];
          furrowPrev = ["alt+," "ctrl+,"];
          quit = ["ctrl+shift+d"];
        };
      };
    };
    "${dir}/models.json" = {
      generator = lib.generators.toJSON {};
      value.providers.vercel-ai-gateway.apiKey = "!cat ${config.users.users.${config.user.name}.home}/Tokens/AI_GATEWAY_API_KEY.txt";
      value.providers.vercel-ai-gateway.models = [
        {
          id = "moonshotai/kimi-k3.1-pro";
          name = "Kimi K3.1 Pro";
          contextWindow = 1048576;
          maxTokens = 1048576;
          input = ["text" "image"];
          reasoning = true;
          compat.allowEmptySignature = true;
          cost = {
            input = 2;
            output = 10;
            cacheRead = 0.2;
            cacheWrite = 0;
          };
        }
        {
          id = "deepseek/deepseek-v4.1-flash-1017";
          name = "DeepSeek V4.1 Flash 1017";
          contextWindow = 1048576;
          maxTokens = 32768;
          input = ["text" "image"];
          reasoning = true;
          cost = {
            input = 0.075;
            output = 0.3;
            cacheRead = 0.0015;
            cacheWrite = 0;
          };
        }
        {
          id = "deepseek/deepseek-v4.1-flash-1017-fast";
          name = "DeepSeek V4.1 Flash 1017 Fast";
          contextWindow = 1048576;
          maxTokens = 32768;
          input = ["text" "image"];
          reasoning = true;
          cost = {
            input = 0.6;
            output = 2.4;
            cacheRead = 0.014;
            cacheWrite = 0;
          };
        }
      ];
      value.providers.openrouter.models = [
        {
          id = "inception/mercury-3";
          name = "Inception: Mercury 3";
          contextWindow = 1000000;
          maxTokens = 131072;
          input = ["text"];
          reasoning = true;
          cost = {
            input = 0.1;
            output = 0.35;
            cacheRead = 0.01;
            cacheWrite = 0;
          };
          thinkingLevelMap = {
            off = null;
            minimal = null;
            low = "low";
            medium = "medium";
            high = "high";
            xhigh = null;
            max = null;
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
      value.mcpServers.jev = {
        command = "${pkgs.nodejs}/bin/node";
        args = ["${./jev-mcp.mjs}"];
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
