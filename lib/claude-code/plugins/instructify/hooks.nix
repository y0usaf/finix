# Hooks configuration for instructify plugin
# Registers the dispatch script for all 12 hook event types
{
  config = builtins.listToAttrs (map (event: {
      name = event;
      value = [
        {
          matcher = "";
          hooks = [
            {
              type = "command";
              command = "\${CLAUDE_PLUGIN_ROOT}/hooks/scripts/instructify-dispatch.sh";
            }
          ];
        }
      ];
    })
    [
      "SessionStart"
      "UserPromptSubmit"
      "PreToolUse"
      "PermissionRequest"
      "PostToolUse"
      "PostToolUseFailure"
      "Notification"
      "SubagentStart"
      "SubagentStop"
      "Stop"
      "PreCompact"
      "SessionEnd"
    ]);

  scripts = {
    "instructify-dispatch.sh" = builtins.readFile ./instructify-dispatch.sh;
  };
}
