# Hooks configuration for codex-mcp plugin
# Plain text stdout with exit 0 adds context to UserPromptSubmit/SessionStart
let
  reminderCommand = ''    printf '%s\n' '<system-reminder>
    Use Codex MCP when seeking reviews or second opinions.
    </system-reminder>''''';
in {
  config = {
    SessionStart = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = reminderCommand;
          }
        ];
      }
    ];
    UserPromptSubmit = [
      {
        matcher = "";
        hooks = [
          {
            type = "command";
            command = reminderCommand;
          }
        ];
      }
    ];
  };
}
