{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.claude-code.enable {
    programs.tweakcc = {
      enable = true;
      settings = {
        misc = {
          hideStartupBanner = true;
          expandThinkingBlocks = false;
        };
        claudeMdAltNames = ["AGENTS.md"];
        toolsets = [
          {
            name = "undefined";
            allowedTools = ["ToolSearch" "Bash" "WebFetch" "WebSearch" "TeamCreate" "TeamDelete" "TaskCreate" "TaskGet" "TaskList" "TaskOutput" "TaskStop" "TaskUpdate" "SendMessage" "Agent"];
          }
        ];
      };
    };
  };
}
