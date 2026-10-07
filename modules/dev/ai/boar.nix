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
    ".local/state/boar/agent/mcp.json" = {
      generator = lib.generators.toJSON {};
      value.mcpServers.donsetch = {
        command = lib.getExe flakeInputs.pi-donsetch.packages.${pkgs.stdenv.hostPlatform.system}.donsetch;
        args = ["mcp"];
      };
    };
  };
}
