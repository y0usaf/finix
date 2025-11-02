{
  includeCoAuthoredBy = false;
  model = "claude-haiku-4-5";
  env = {
    MAX_THINKING_TOKENS = "32000";
  };
  statusLine = {
    type = "command";
    command = "bunx ccusage statusline";
  };
  hooks = {
    Notification = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "bun ~/.claude/hooks/notification.ts --notify";
          }
        ];
      }
    ];
    Stop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "bun ~/.claude/hooks/stop.ts --chat";
          }
        ];
      }
    ];
    SubagentStop = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = "bun ~/.claude/hooks/subagent_stop.ts";
          }
        ];
      }
    ];
    PreToolUse = [];
    PostToolUse = [];
  };
}
