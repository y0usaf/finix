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
            scout = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-fast";
            ship = "anthropic/claude-opus-5-5";
          };
          defaultRole = "scout";
        };
        defaultProvider = "anthropic";
        defaultModel = "claude-opus-5-5";
        defaultThinkingLevel = "xhigh";
        memory.model = "vercel-ai-gateway/deepseek/deepseek-v4.1-flash-fast";
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
