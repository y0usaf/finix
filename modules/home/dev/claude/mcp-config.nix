{
  config,
  lib,
  pkgs,
  ...
}: {
  mcpConfig = {
    mcpServers = {
      Context7 = {
        command = "npx";
        args = ["-y" "@upstash/context7-mcp"];
      };
      ParallelTasks = {
        command = "npx";
        args = ["-y" "@captaincrouton89/claude-parallel-tasks-mcp"];
      };
    };
  };
}
